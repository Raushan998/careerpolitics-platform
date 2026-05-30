FactoryBot.define do
  factory :mock_test_answer do
    association :mock_test_question
    mock_test_session { mock_test_question.mock_test_session }
    user { mock_test_session.user }
    selected_options { ["B"] }
    text_answer { nil }

    trait :graded do
      awarded_points { 1.0 }
      correct { true }
    end
  end
end
