require "rails_helper"

RSpec.describe MockTests::CreateSession, type: :service do
  let(:user) { create(:user) }
  let(:exam) { create(:exam, published: true, default_question_count: 20, default_duration_minutes: 30, difficulty: "medium", subforem_id: nil) }

  before do
    allow(MockTests::GenerationWorker).to receive(:perform_async)
  end

  describe ".call" do
    it "creates a generating session with snapshotted exam params" do
      session = described_class.call(user: user, exam: exam)

      expect(session).to be_persisted
      expect(session.status).to eq("generating")
      expect(session.user).to eq(user)
      expect(session.exam).to eq(exam)
      expect(session.duration_minutes).to eq(30)
      expect(session.difficulty).to eq("medium")
      expect(session.ai_generation_version).to eq(Ai::MockTestGenerator::VERSION)
    end

    it "enqueues the generation worker" do
      session = described_class.call(user: user, exam: exam)
      expect(MockTests::GenerationWorker).to have_received(:perform_async).with(session.id)
    end

    it "defaults question count to the exam default" do
      session = described_class.call(user: user, exam: exam)
      expect(session.question_count).to eq(20)
    end

    it "clamps a requested question count above the exam default" do
      session = described_class.call(user: user, exam: exam, question_count: 999)
      expect(session.question_count).to eq(20)
    end

    it "clamps a requested question count below the minimum" do
      session = described_class.call(user: user, exam: exam, question_count: 0)
      expect(session.question_count).to eq(1)
    end

    it "uses a valid requested difficulty over the exam default" do
      session = described_class.call(user: user, exam: exam, difficulty: "hard")
      expect(session.difficulty).to eq("hard")
    end

    it "falls back to the exam difficulty for an invalid requested difficulty" do
      session = described_class.call(user: user, exam: exam, difficulty: "impossible")
      expect(session.difficulty).to eq("medium")
    end

    context "when the exam is not published" do
      let(:exam) { create(:exam, :unpublished) }

      it "raises ExamNotAvailable and enqueues nothing" do
        expect { described_class.call(user: user, exam: exam) }
          .to raise_error(described_class::ExamNotAvailable)
        expect(MockTests::GenerationWorker).not_to have_received(:perform_async)
      end
    end

    context "subforem scoping" do
      it "allows a global exam in any subforem" do
        subforem = create(:subforem)
        session = described_class.call(user: user, exam: exam, subforem_id: subforem.id)
        expect(session.subforem_id).to eq(subforem.id)
      end

      it "allows a subforem exam in its own subforem" do
        subforem = create(:subforem)
        scoped_exam = create(:exam, published: true, subforem_id: subforem.id)
        session = described_class.call(user: user, exam: scoped_exam, subforem_id: subforem.id)
        expect(session.subforem_id).to eq(subforem.id)
      end

      it "rejects a subforem exam requested from a different subforem" do
        scoped_exam = create(:exam, published: true, subforem_id: create(:subforem).id)
        other_subforem = create(:subforem)

        expect { described_class.call(user: user, exam: scoped_exam, subforem_id: other_subforem.id) }
          .to raise_error(described_class::ExamNotAvailable)
      end
    end
  end
end
