FactoryBot.define do
  factory :mock_test_question do
    association :mock_test_session
    sequence(:position) { |n| n }
    question_type { "mcq_single" }
    prompt { "What is the capital of India?" }
    options do
      [
        { "key" => "A", "text" => "Mumbai" },
        { "key" => "B", "text" => "New Delhi" },
        { "key" => "C", "text" => "Kolkata" },
        { "key" => "D", "text" => "Chennai" }
      ]
    end
    correct_answer { ["B"] }
    points { 1.0 }
    explanation { "New Delhi is the capital of India." }

    trait :mcq_multi do
      question_type { "mcq_multi" }
      prompt { "Which of the following are Union Territories of India?" }
      correct_answer { %w[A C] }
    end
  end
end
