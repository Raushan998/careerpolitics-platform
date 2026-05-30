class MockTestAnswer < ApplicationRecord
  belongs_to :mock_test_question
  belongs_to :mock_test_session
  belongs_to :user

  # One answer row per question; upserted as the user changes their response.
  validates :mock_test_question_id, uniqueness: true

  scope :for_session, ->(session) { where(mock_test_session: session) }
end
