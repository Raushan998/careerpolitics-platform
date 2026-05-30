module MockTests
  ##
  # Creates a MockTestSession for a user against a curated, published exam and
  # enqueues background generation of the paper.
  #
  # The requested question count is clamped to a sane range bounded by the exam's
  # default (the exam catalog is the source of truth — users never free-type the
  # exam, so there is no prompt-injection surface). Difficulty falls back to the
  # exam default and is validated against Exam::DIFFICULTIES.
  #
  # Returns the persisted session. Callers (controller/worker) handle the rest.
  class CreateSession
    MIN_QUESTION_COUNT = 1

    class ExamNotAvailable < StandardError; end

    def self.call(user:, exam:, question_count: nil, difficulty: nil, subforem_id: nil)
      new(
        user: user,
        exam: exam,
        question_count: question_count,
        difficulty: difficulty,
        subforem_id: subforem_id,
      ).call
    end

    def initialize(user:, exam:, question_count: nil, difficulty: nil, subforem_id: nil)
      @user = user
      @exam = exam
      @requested_question_count = question_count
      @requested_difficulty = difficulty
      @subforem_id = subforem_id || RequestStore.store[:subforem_id]
    end

    def call
      validate_exam_available!

      session = MockTestSession.create!(
        user: @user,
        exam: @exam,
        subforem_id: @subforem_id,
        status: MockTestSession::STATUSES[:generating],
        question_count: clamped_question_count,
        duration_minutes: @exam.default_duration_minutes,
        difficulty: resolved_difficulty,
        ai_generation_version: Ai::MockTestGenerator::VERSION,
      )

      MockTests::GenerationWorker.perform_async(session.id)

      session
    end

    private

    def validate_exam_available!
      raise ExamNotAvailable, "Exam is not published" unless @exam.published?
      return if [@subforem_id, nil].include?(@exam.subforem_id)

      raise ExamNotAvailable, "Exam is not visible in this subforem"
    end

    # Upper bound is the exam's configured default; this both caps cost and keeps
    # the requested size aligned with the curated exam pattern.
    def clamped_question_count
      max = @exam.default_question_count
      requested = @requested_question_count.presence&.to_i || max
      requested.clamp(MIN_QUESTION_COUNT, max)
    end

    def resolved_difficulty
      candidate = @requested_difficulty.presence || @exam.difficulty
      Exam::DIFFICULTIES.include?(candidate) ? candidate : nil
    end
  end
end
