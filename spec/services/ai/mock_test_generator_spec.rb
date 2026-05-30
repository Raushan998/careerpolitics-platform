require "rails_helper"

RSpec.describe Ai::MockTestGenerator, type: :service do
  let(:exam) { create(:exam, name: "UPSC Prelims") }
  let(:ai_client) { instance_double(Ai::Base) }

  def valid_question(key_correct: "B", type: "mcq_single")
    {
      "type" => type,
      "prompt" => "What is the capital of India?",
      "options" => [
        { "key" => "A", "text" => "Mumbai" },
        { "key" => "B", "text" => "New Delhi" },
        { "key" => "C", "text" => "Kolkata" },
        { "key" => "D", "text" => "Chennai" }
      ],
      "correct_answer" => [key_correct],
      "points" => 1.0,
      "explanation" => "New Delhi is the capital."
    }
  end

  def payload(questions)
    { "questions" => questions }.to_json
  end

  before do
    allow(Settings::Community).to receive(:community_description).and_return("A community of learners.")
  end

  def build_generator(question_count: 2, difficulty: "medium")
    described_class.new(
      exam: exam,
      question_count: question_count,
      difficulty: difficulty,
      ai_client: ai_client,
    )
  end

  describe "#generate" do
    context "when the AI returns valid JSON" do
      before do
        allow(ai_client).to receive(:call).and_return(payload([valid_question, valid_question(key_correct: "A")]))
      end

      it "returns normalized question hashes" do
        result = build_generator(question_count: 2).generate

        expect(result.size).to eq(2)
        first = result.first
        expect(first[:position]).to eq(1)
        expect(first[:question_type]).to eq("mcq_single")
        expect(first[:options]).to eq(
          [
            { key: "A", text: "Mumbai" },
            { key: "B", text: "New Delhi" },
            { key: "C", text: "Kolkata" },
            { key: "D", text: "Chennai" }
          ],
        )
        expect(first[:correct_answer]).to eq(["B"])
        expect(first[:points]).to eq(1.0)
      end

      it "requests JSON response mime type" do
        build_generator(question_count: 2).generate
        expect(ai_client).to have_received(:call).with(anything, hash_including(response_mime_type: "application/json"))
      end
    end

    context "when the AI wraps JSON in markdown fences" do
      before do
        fenced = "```json\n#{payload([valid_question, valid_question])}\n```"
        allow(ai_client).to receive(:call).and_return(fenced)
      end

      it "strips the fences and parses the questions" do
        result = build_generator(question_count: 2).generate
        expect(result.size).to eq(2)
      end
    end

    context "when some questions are invalid" do
      let(:bad_no_prompt) { valid_question.merge("prompt" => "") }
      let(:bad_correct_key) { valid_question.merge("correct_answer" => ["Z"]) }
      let(:bad_multi_as_single) { valid_question.merge("correct_answer" => %w[A B]) }

      before do
        questions = [valid_question, valid_question, bad_no_prompt, bad_correct_key, bad_multi_as_single]
        allow(ai_client).to receive(:call).and_return(payload(questions))
      end

      it "drops invalid questions and keeps the valid ones" do
        result = build_generator(question_count: 5).generate
        expect(result.size).to eq(2)
        expect(result.map { |q| q[:position] }).to eq([1, 2])
      end
    end

    context "when fewer than the minimum acceptable questions survive" do
      before do
        # Request 4 -> minimum acceptable is 2; only 1 valid survives.
        allow(ai_client).to receive(:call)
          .and_return(payload([valid_question, valid_question.merge("prompt" => "")]))
      end

      it "raises a GenerationError after exhausting retries" do
        expect { build_generator(question_count: 4).generate }
          .to raise_error(Ai::MockTestGenerator::GenerationError)
        expect(ai_client).to have_received(:call).exactly(3).times
      end
    end

    context "when the AI returns malformed JSON" do
      before do
        allow(ai_client).to receive(:call).and_return("not json at all")
      end

      it "retries then raises a GenerationError" do
        expect { build_generator(question_count: 2).generate }
          .to raise_error(Ai::MockTestGenerator::GenerationError)
        expect(ai_client).to have_received(:call).exactly(3).times
      end
    end

    context "when the AI raises and then succeeds on retry" do
      before do
        call_count = 0
        allow(ai_client).to receive(:call) do
          call_count += 1
          raise StandardError, "transient" if call_count < 2

          payload([valid_question, valid_question])
        end
      end

      it "returns the paper after the successful retry" do
        result = build_generator(question_count: 2).generate
        expect(result.size).to eq(2)
        expect(ai_client).to have_received(:call).twice
      end
    end

    context "when an mcq_multi question is returned" do
      let(:multi) do
        valid_question(type: "mcq_multi").merge("correct_answer" => %w[A C])
      end

      before do
        allow(ai_client).to receive(:call).and_return(payload([multi, valid_question]))
      end

      it "accepts it when at least two correct keys are valid" do
        result = build_generator(question_count: 2).generate
        expect(result.first[:question_type]).to eq("mcq_multi")
        expect(result.first[:correct_answer]).to eq(%w[A C])
      end
    end

    context "when more questions than requested are returned" do
      before do
        allow(ai_client).to receive(:call).and_return(payload(Array.new(5) { valid_question }))
      end

      it "truncates to the requested count" do
        result = build_generator(question_count: 3).generate
        expect(result.size).to eq(3)
      end
    end
  end
end
