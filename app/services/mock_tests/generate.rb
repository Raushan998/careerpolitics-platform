module MockTests
  ##
  # Orchestrates AI generation of a mock test paper for a session: runs
  # Ai::MockTestGenerator, persists the resulting questions in a single
  # transaction, and flips the session status to `ready` (or `failed`).
  #
  # Idempotent on retries: generation only runs while the session is still in
  # the `generating` state, and existing questions are cleared before re-insert
  # so a Sidekiq retry cannot duplicate a paper.
  class Generate
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    def call
      return unless @session.generating?

      questions = Ai::MockTestGenerator.new(
        exam: @session.exam,
        question_count: @session.question_count,
        difficulty: @session.difficulty,
        affected_user: @session.user,
      ).generate

      persist!(questions)
      @session
    rescue StandardError => e
      Rails.logger.error("MockTests::Generate failed for session #{@session.id}: #{e}")
      mark_failed!(e.message)
      @session
    end

    private

    def persist!(questions)
      MockTestSession.transaction do
        @session.mock_test_questions.delete_all

        questions.each do |attrs|
          @session.mock_test_questions.create!(
            position: attrs[:position],
            question_type: attrs[:question_type],
            prompt: attrs[:prompt],
            options: attrs[:options],
            correct_answer: attrs[:correct_answer],
            points: attrs[:points],
            explanation: attrs[:explanation],
          )
        end

        max_score = questions.sum { |q| q[:points] }
        @session.update!(
          status: MockTestSession::STATUSES[:ready],
          max_score: max_score,
          generation_error: nil,
        )
      end
    end

    def mark_failed!(message)
      @session.update!(
        status: MockTestSession::STATUSES[:failed],
        generation_error: message,
      )
    rescue StandardError => e
      Rails.logger.error("MockTests::Generate could not mark session #{@session.id} failed: #{e}")
    end
  end
end
