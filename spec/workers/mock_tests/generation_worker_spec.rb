require "rails_helper"

RSpec.describe MockTests::GenerationWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "delegates to MockTests::Generate for an existing session" do
      session = create(:mock_test_session)
      allow(MockTestSession).to receive(:find_by).with(id: session.id).and_return(session)
      allow(MockTests::Generate).to receive(:call)

      worker.perform(session.id)

      expect(MockTests::Generate).to have_received(:call).with(session: session)
    end

    it "does nothing when the session is missing" do
      allow(MockTests::Generate).to receive(:call)

      worker.perform(-1)

      expect(MockTests::Generate).not_to have_received(:call)
    end
  end
end
