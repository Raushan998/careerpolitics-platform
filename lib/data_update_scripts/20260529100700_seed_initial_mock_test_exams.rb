module DataUpdateScripts
  class SeedInitialMockTestExams
    # Initial admin-curated exam allowlist. Exams are global (subforem_id: nil)
    # so they are selectable across all subforems. Idempotent: keyed on
    # [slug, subforem_id], so re-running will not create duplicates.
    EXAMS = [
      {
        name: "UPSC Civil Services Prelims",
        category: "Civil Services",
        difficulty: "hard",
        default_question_count: 20,
        default_duration_minutes: 30,
        position: 1,
        description: "Practice paper modeled on the UPSC Civil Services Preliminary examination (General Studies Paper I).",
        syllabus_context: <<~CONTEXT.strip
          Exam: UPSC Civil Services Preliminary (General Studies Paper I).
          Pattern: 100 multiple-choice questions, single correct option, negative marking in the real exam.
          Topics: Indian polity and governance, modern Indian history and the freedom struggle,
          Indian and world geography, economic and social development, general science,
          environment and ecology, and current events of national and international importance.
        CONTEXT
      },
      {
        name: "SSC CGL Tier I",
        category: "Staff Selection",
        difficulty: "medium",
        default_question_count: 20,
        default_duration_minutes: 30,
        position: 2,
        description: "Practice paper modeled on the SSC Combined Graduate Level (Tier I) examination.",
        syllabus_context: <<~CONTEXT.strip
          Exam: SSC Combined Graduate Level Tier I.
          Pattern: multiple-choice questions, single correct option.
          Topics: General Intelligence and Reasoning, General Awareness, Quantitative Aptitude,
          and English Comprehension.
        CONTEXT
      },
      {
        name: "Railway NTPC (CBT 1)",
        category: "Railways",
        difficulty: "medium",
        default_question_count: 20,
        default_duration_minutes: 30,
        position: 3,
        description: "Practice paper modeled on the RRB NTPC Computer Based Test (Stage 1).",
        syllabus_context: <<~CONTEXT.strip
          Exam: Railway Recruitment Board NTPC CBT 1.
          Pattern: multiple-choice questions, single correct option.
          Topics: Mathematics, General Intelligence and Reasoning, and General Awareness
          (current affairs, history, geography, polity, economics, and general science).
        CONTEXT
      }
    ].freeze

    def run
      EXAMS.each do |attrs|
        slug = attrs[:name].parameterize
        next if Exam.exists?(slug: slug, subforem_id: nil)

        Exam.create!(attrs.merge(slug: slug, subforem_id: nil, published: true))
      end
    end
  end
end
