require "rails_helper"

RSpec.describe MockTestQuestion, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:mock_test_session) }
    it { is_expected.to have_one(:mock_test_answer).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:mock_test_question) }

    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:question_type) }
    it { is_expected.to validate_presence_of(:prompt) }
    it { is_expected.to validate_inclusion_of(:question_type).in_array(described_class::QUESTION_TYPES.values) }

    it "requires positive points" do
      question = build(:mock_test_question, points: 0)
      expect(question).not_to be_valid
      expect(question.errors[:points]).to be_present
    end
  end

  describe "jsonb columns" do
    it "persists and reloads options and correct_answer" do
      question = create(:mock_test_question)
      question.reload
      expect(question.options).to eq(
        [
          { "key" => "A", "text" => "Mumbai" },
          { "key" => "B", "text" => "New Delhi" },
          { "key" => "C", "text" => "Kolkata" },
          { "key" => "D", "text" => "Chennai" }
        ],
      )
      expect(question.correct_answer).to eq(["B"])
    end

    it "defaults options to an empty array" do
      question = create(:mock_test_question, options: nil)
      question.options = []
      question.save!
      expect(question.reload.options).to eq([])
    end
  end

  describe "#mcq? and #subjective?" do
    it "identifies mcq types" do
      expect(build(:mock_test_question, question_type: "mcq_single")).to be_mcq
      expect(build(:mock_test_question, question_type: "mcq_multi")).to be_mcq
    end

    it "identifies subjective types" do
      expect(build(:mock_test_question, question_type: "short_answer")).to be_subjective
    end
  end

  describe "uniqueness of position within a session" do
    it "rejects a duplicate position for the same session" do
      session = create(:mock_test_session, :ready)
      create(:mock_test_question, mock_test_session: session, position: 1)
      duplicate = build(:mock_test_question, mock_test_session: session, position: 1)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
