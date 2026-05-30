class Exam < ApplicationRecord
  DIFFICULTIES = %w[easy medium hard].freeze

  belongs_to :subforem, optional: true

  has_many :mock_test_sessions, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :subforem_id }
  validates :difficulty, inclusion: { in: DIFFICULTIES }, allow_nil: true
  validates :default_question_count, numericality: { only_integer: true, greater_than: 0 }
  validates :default_duration_minutes, numericality: { only_integer: true, greater_than: 0 }

  before_validation :generate_slug, on: :create

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :from_subforem, lambda { |subforem_id = nil|
    subforem_id ||= RequestStore.store[:subforem_id]
    where(subforem_id: [subforem_id, nil])
  }

  def to_param
    slug
  end

  def path
    "/mock-tests/exams/#{slug}"
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.parameterize
    self.slug = base_slug
    counter = 1
    while Exam.exists?(slug: self.slug, subforem_id: subforem_id)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
