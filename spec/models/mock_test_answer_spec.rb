require "rails_helper"

RSpec.describe MockTestAnswer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:mock_test_question) }
    it { is_expected.to belong_to(:mock_test_session) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { create(:mock_test_answer) }

    it { is_expected.to validate_uniqueness_of(:mock_test_question_id) }
  end

  describe "one answer per question" do
    it "rejects a second answer row for the same question" do
      answer = create(:mock_test_answer)
      duplicate = build(
        :mock_test_answer,
        mock_test_question: answer.mock_test_question,
        mock_test_session: answer.mock_test_session,
        user: answer.user,
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:mock_test_question_id]).to be_present
    end
  end

  describe ".for_session" do
    it "returns answers scoped to a session" do
      answer = create(:mock_test_answer)
      create(:mock_test_answer)

      expect(described_class.for_session(answer.mock_test_session)).to contain_exactly(answer)
    end
  end
end
