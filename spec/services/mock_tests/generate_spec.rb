require "rails_helper"

RSpec.describe MockTests::Generate, type: :service do
  let(:session) { create(:mock_test_session, status: "generating", question_count: 2) }
  let(:generator) { instance_double(Ai::MockTestGenerator) }

  let(:generated_questions) do
    [
      {
        position: 1,
        question_type: "mcq_single",
        prompt: "Q1?",
        options: [{ key: "A", text: "x" }, { key: "B", text: "y" }],
        correct_answer: ["A"],
        points: 1.0,
        explanation: "because"
      },
      {
        position: 2,
        question_type: "mcq_single",
        prompt: "Q2?",
        options: [{ key: "A", text: "x" }, { key: "B", text: "y" }],
        correct_answer: ["B"],
        points: 2.0,
        explanation: "because"
      }
    ]
  end

  before do
    allow(Ai::MockTestGenerator).to receive(:new).and_return(generator)
  end

  describe ".call" do
    context "when generation succeeds" do
      before do
        allow(generator).to receive(:generate).and_return(generated_questions)
      end

      it "persists the questions" do
        described_class.call(session: session)
        expect(session.reload.mock_test_questions.count).to eq(2)
      end

      it "marks the session ready and sets max_score" do
        described_class.call(session: session)
        session.reload
        expect(session.status).to eq("ready")
        expect(session.max_score).to eq(3.0)
        expect(session.generation_error).to be_nil
      end

      it "passes the exam and session params to the generator" do
        described_class.call(session: session)
        expect(Ai::MockTestGenerator).to have_received(:new).with(
          exam: session.exam,
          question_count: session.question_count,
          difficulty: session.difficulty,
          affected_user: session.user,
        )
      end

      it "does not duplicate questions when run twice on a re-set session" do
        described_class.call(session: session)
        session.update!(status: "generating")
        described_class.call(session: session)
        expect(session.reload.mock_test_questions.count).to eq(2)
      end
    end

    context "when the session is not in the generating state" do
      let(:session) { create(:mock_test_session, :ready) }

      before do
        allow(generator).to receive(:generate)
      end

      it "does not invoke the generator and leaves the session untouched" do
        described_class.call(session: session)
        expect(generator).not_to have_received(:generate)
        expect(session.reload.status).to eq("ready")
        expect(session.mock_test_questions).to be_empty
      end
    end

    context "when generation raises" do
      before do
        allow(generator).to receive(:generate).and_raise(Ai::MockTestGenerator::GenerationError, "boom")
      end

      it "marks the session failed and records the error" do
        described_class.call(session: session)
        session.reload
        expect(session.status).to eq("failed")
        expect(session.generation_error).to eq("boom")
      end

      it "does not persist any questions" do
        described_class.call(session: session)
        expect(session.reload.mock_test_questions).to be_empty
      end
    end
  end
end
