module MockTests
  class GenerationWorker
    include Sidekiq::Job

    # Coalesce duplicate enqueues for the same session (storm prevention per
    # AGENTS.md). Generation is expensive (a Gemini call), so we only ever want
    # one in flight per session.
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(session_id)
      session = MockTestSession.find_by(id: session_id)
      return unless session

      MockTests::Generate.call(session: session)
    end
  end
end
