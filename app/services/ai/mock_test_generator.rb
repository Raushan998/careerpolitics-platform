module Ai
  ##
  # Generates a mock test paper for a given Exam via Gemini (through Ai::Base).
  #
  # v1 ships MCQ-only papers (single- and multi-correct). The data model and
  # the question schema leave room for subjective `short_answer` questions, but
  # this generator does not request them yet (AI subjective grading would roughly
  # double the per-attempt cost — see plan §11).
  #
  # Follows the same Ai::Base wrapper pattern as Ai::ContentModerationLabeler:
  # JSON response mode, markdown-fence cleanup, retry/fallback, and a normalized
  # array of question hashes returned to the caller for persistence.
  class MockTestGenerator
    VERSION = "1.0".freeze

    QUESTION_TYPES = %w[mcq_single mcq_multi].freeze
    MIN_OPTIONS = 2

    # @param exam [Exam] the curated exam driving generation.
    # @param question_count [Integer] number of questions requested.
    # @param difficulty [String] one of Exam::DIFFICULTIES.
    # @param ai_client [Ai::Base, nil] injectable client (for tests).
    # @param affected_user [User, nil] user the generation is attributed to in ai_audits.
    def initialize(exam:, question_count:, difficulty:, ai_client: nil, affected_user: nil)
      @exam = exam
      @question_count = question_count.to_i
      @difficulty = difficulty
      @ai_client = ai_client || Ai::Base.new(wrapper: self, affected_user: affected_user)
    end

    ##
    # Generates and validates a paper.
    # Retries up to 2 times on error/insufficient questions before raising.
    #
    # @return [Array<Hash>] normalized question hashes.
    # @raise [GenerationError] when no valid paper could be produced.
    def generate
      attempt = 0
      max_retries = 2

      begin
        attempt += 1
        response = @ai_client.call(build_prompt, retry_count: attempt - 1, response_mime_type: "application/json")
        questions = parse_and_validate(response)

        if questions.size < minimum_acceptable_count
          raise GenerationError, "Only #{questions.size} valid questions produced (need >= #{minimum_acceptable_count})"
        end

        questions
      rescue StandardError => e
        Rails.logger.error("Ai::MockTestGenerator failed (attempt #{attempt}/#{max_retries + 1}): #{e}")

        if attempt <= max_retries
          sleep_duration = attempt * 2
          Rails.logger.info("Retrying mock test generation (attempt #{attempt + 1}/#{max_retries + 1}) after #{sleep_duration}s")
          sleep(sleep_duration) unless Rails.env.test?
          retry
        else
          Rails.logger.error("Ai::MockTestGenerator failed after #{max_retries + 1} attempts")
          raise GenerationError, "Mock test generation failed after #{max_retries + 1} attempts: #{e.message}"
        end
      end
    end

    private

    attr_reader :exam, :question_count, :difficulty, :ai_client

    def minimum_acceptable_count
      (question_count / 2.0).ceil
    end

    def build_prompt
      community_description = Settings::Community.community_description(subforem_id: exam.subforem_id)

      <<~PROMPT
        You are an expert exam-setter creating a practice mock test paper.

        **Community Context:**
        #{community_description.presence || 'A community of learners preparing for competitive exams.'}

        **Exam:**
        Name: #{exam.name}
        Category: #{exam.category.presence || 'General'}
        Syllabus / pattern context:
        #{exam.syllabus_context.presence || 'No additional syllabus context provided; use widely accepted topics for this exam.'}

        **Requirements:**
        - Generate exactly #{question_count} multiple-choice questions at "#{difficulty}" difficulty.
        - Each question must be factually accurate, unambiguous, and relevant to the exam above.
        - Use only these question types:
          - "mcq_single": exactly one correct option.
          - "mcq_multi": two or more correct options.
        - Each question must have at least #{MIN_OPTIONS} options with unique single-letter keys ("A", "B", "C", "D", ...).
        - "correct_answer" must be an array of option keys that exist in that question's "options".
        - Provide a concise "explanation" for each question.
        - "points" is a positive number (use 1.0 unless a question warrants more).

        **Response format:**
        Respond ONLY with a raw JSON object (no markdown code fences) matching this schema:
        {
          "questions": [
            {
              "type": "mcq_single",
              "prompt": "Question text in markdown.",
              "options": [
                {"key": "A", "text": "First option"},
                {"key": "B", "text": "Second option"},
                {"key": "C", "text": "Third option"},
                {"key": "D", "text": "Fourth option"}
              ],
              "correct_answer": ["B"],
              "points": 1.0,
              "explanation": "Why B is correct."
            }
          ]
        }
      PROMPT
    end

    ##
    # Parses and validates the AI response into normalized question hashes.
    # Invalid questions are dropped; the caller decides whether enough survived.
    #
    # @param response [String] raw text from the AI.
    # @return [Array<Hash>] normalized questions with symbol keys.
    def parse_and_validate(response)
      raise GenerationError, "Empty AI response" if response.blank?

      cleaned = response.strip.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      data = JSON.parse(cleaned)

      raise GenerationError, "Response is not a JSON object" unless data.is_a?(Hash)

      raw_questions = data["questions"]
      raise GenerationError, '"questions" must be an array' unless raw_questions.is_a?(Array)

      normalized = raw_questions.filter_map.with_index(1) do |raw, position|
        normalize_question(raw, position)
      end

      normalized.take(question_count)
    rescue JSON::ParserError => e
      raise GenerationError, "Invalid JSON: #{e.message}"
    end

    def normalize_question(raw, position)
      return nil unless raw.is_a?(Hash)

      type = raw["type"].to_s
      return nil unless QUESTION_TYPES.include?(type)

      prompt = raw["prompt"].to_s.strip
      return nil if prompt.blank?

      options = normalize_options(raw["options"])
      return nil if options.size < MIN_OPTIONS

      option_keys = options.map { |o| o[:key] }
      return nil unless option_keys.uniq.size == option_keys.size

      correct = Array(raw["correct_answer"]).map(&:to_s)
      return nil if correct.empty?
      return nil unless correct.all? { |key| option_keys.include?(key) }
      return nil if type == "mcq_single" && correct.size != 1
      return nil if type == "mcq_multi" && correct.size < 2

      points = raw["points"].to_f
      points = 1.0 unless points.positive?

      {
        position: position,
        question_type: type,
        prompt: prompt,
        options: options,
        correct_answer: correct,
        points: points,
        explanation: raw["explanation"].to_s.strip.presence
      }
    end

    def normalize_options(raw_options)
      return [] unless raw_options.is_a?(Array)

      raw_options.filter_map do |opt|
        next unless opt.is_a?(Hash)

        key = opt["key"].to_s.strip
        text = opt["text"].to_s.strip
        next if key.blank? || text.blank?

        { key: key, text: text }
      end
    end

    class GenerationError < StandardError; end
  end
end
