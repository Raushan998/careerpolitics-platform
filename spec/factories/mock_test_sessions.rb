FactoryBot.define do
  factory :mock_test_session do
    association :user
    association :exam
    subforem_id { nil }
    status { "generating" }
    question_count { 20 }
    duration_minutes { 30 }
    difficulty { "medium" }
    ai_generation_version { Ai::MockTestGenerator::VERSION }

    trait :ready do
      status { "ready" }
      max_score { 20.0 }
    end

    trait :in_progress do
      status { "in_progress" }
      max_score { 20.0 }
      started_at { Time.current }
    end

    trait :submitted do
      status { "submitted" }
      max_score { 20.0 }
      started_at { 30.minutes.ago }
      submitted_at { Time.current }
    end

    trait :graded do
      status { "graded" }
      score { 15.0 }
      max_score { 20.0 }
      started_at { 1.hour.ago }
      submitted_at { 30.minutes.ago }
      graded_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      generation_error { "AI generation failed" }
    end
  end
end
