class CreateMockTestAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :mock_test_answers do |t|
      # Unique: one answer row per question (upserted on change)
      t.references :mock_test_question, null: false, foreign_key: true, index: { unique: true }
      t.references :mock_test_session, null: false, foreign_key: true # Denormalized for fast session-level queries
      t.references :user, null: false, foreign_key: true # Defense-in-depth
      t.jsonb :selected_options, default: [] # Chosen MCQ keys
      t.text :text_answer # Subjective answer
      t.float :awarded_points # Nullable until graded
      t.boolean :correct # Nullable until graded
      t.text :ai_feedback # Subjective grading feedback

      t.timestamps
    end
  end
end
