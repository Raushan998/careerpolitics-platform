class MockTestSession < ApplicationRecord
  # Simple string-based state machine (KISS — mirrors JobPost's plain
  # booleans/scopes rather than introducing AASM).
  STATUSES = {
    generating: "generating",
    ready: "ready",
    in_progress: "in_progress",
    submitted: "submitted",
    graded: "graded",
    failed: "failed"
  }.freeze

  belongs_to :user
  belongs_to :exam
  belongs_to :subforem, optional: true

  has_many :mock_test_questions, -> { order(position: :asc) }, dependent: :destroy
  has_many :mock_test_answers, through: :mock_test_questions

  validates :status, presence: true, inclusion: { in: STATUSES.values }
  validates :question_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :difficulty, inclusion: { in: Exam::DIFFICULTIES }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :from_subforem, lambda { |subforem_id = nil|
    subforem_id ||= RequestStore.store[:subforem_id]
    where(subforem_id: [subforem_id, nil])
  }

  STATUSES.each do |name, value|
    scope name, -> { where(status: value) }

    define_method("#{name}?") { status == value }
  end

  def path
    "/mock-tests/#{id}"
  end
end
