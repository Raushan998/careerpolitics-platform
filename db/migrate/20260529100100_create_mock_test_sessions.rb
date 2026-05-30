class CreateMockTestSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :mock_test_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.references :subforem, null: true, foreign_key: true # Denormalized for scoping/reporting
      t.string :status, null: false, default: "generating"
      t.integer :question_count # Snapshot of requested count
      t.integer :duration_minutes # Snapshot
      t.string :difficulty # Snapshot
      t.float :score # Nullable until graded
      t.float :max_score # Total achievable
      t.string :ai_generation_version # Ai::MockTestGenerator::VERSION for auditability
      t.datetime :started_at
      t.datetime :submitted_at
      t.datetime :graded_at
      t.text :generation_error # Populated on failed

      t.timestamps
    end
  end
end
