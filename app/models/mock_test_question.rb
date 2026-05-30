class MockTestQuestion < ApplicationRecord
  QUESTION_TYPES = {
    mcq_single: "mcq_single",
    mcq_multi: "mcq_multi",
    short_answer: "short_answer"
  }.freeze

  MCQ_TYPES = %w[mcq_single mcq_multi].freeze

  belongs_to :mock_test_session

  has_one :mock_test_answer, dependent: :destroy

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES.values }
  validates :prompt, presence: true
  validates :points, numericality: { greater_than: 0 }

  scope :ordered, -> { order(position: :asc) }

  def mcq?
    MCQ_TYPES.include?(question_type)
  end

  def subjective?
    question_type == QUESTION_TYPES[:short_answer]
  end
end
