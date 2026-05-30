FactoryBot.define do
  factory :exam do
    sequence(:name) { |n| "UPSC Civil Services Prelims #{n}" }
    sequence(:slug) { |n| "upsc-civil-services-prelims-#{n}" }
    description { "Practice paper for the preliminary examination." }
    category { "Civil Services" }
    syllabus_context { "Indian polity, history, geography, economy, and current affairs." }
    default_question_count { 20 }
    default_duration_minutes { 30 }
    difficulty { "medium" }
    published { true }
    position { 0 }
    subforem_id { nil }

    trait :unpublished do
      published { false }
    end
  end
end
