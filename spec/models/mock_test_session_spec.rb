require "rails_helper"

RSpec.describe MockTestSession, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:exam) }
    it { is_expected.to belong_to(:subforem).optional }
    it { is_expected.to have_many(:mock_test_questions).dependent(:destroy) }
    it { is_expected.to have_many(:mock_test_answers).through(:mock_test_questions) }
  end

  describe "validations" do
    subject { build(:mock_test_session) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES.values) }
    it { is_expected.to validate_inclusion_of(:difficulty).in_array(Exam::DIFFICULTIES).allow_nil }
  end

  describe "status predicates and scopes" do
    described_class::STATUSES.each do |name, value|
      it "defines ##{name}? and the .#{name} scope" do
        session = create(:mock_test_session, status: value)
        expect(session.public_send("#{name}?")).to be(true)
        expect(described_class.public_send(name)).to include(session)
      end
    end
  end

  describe "dependent destroy" do
    it "destroys questions and their answers when destroyed" do
      session = create(:mock_test_session, :ready)
      question = create(:mock_test_question, mock_test_session: session)
      create(:mock_test_answer, mock_test_question: question)

      expect { session.destroy }
        .to change(MockTestQuestion, :count).by(-1)
        .and change(MockTestAnswer, :count).by(-1)
    end
  end

  describe ".from_subforem" do
    it "includes sessions for the subforem and global sessions" do
      subforem = create(:subforem)
      global = create(:mock_test_session, subforem_id: nil)
      scoped = create(:mock_test_session, subforem_id: subforem.id)
      create(:mock_test_session, subforem_id: create(:subforem).id)

      expect(described_class.from_subforem(subforem.id)).to contain_exactly(global, scoped)
    end
  end

  describe "mock_test_questions ordering" do
    it "returns questions ordered by position" do
      session = create(:mock_test_session, :ready)
      second = create(:mock_test_question, mock_test_session: session, position: 2)
      first = create(:mock_test_question, mock_test_session: session, position: 1)

      expect(session.mock_test_questions.to_a).to eq([first, second])
    end
  end
end
