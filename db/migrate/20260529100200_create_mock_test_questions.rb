class CreateMockTestQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :mock_test_questions do |t|
      t.references :mock_test_session, null: false, foreign_key: true
      t.integer :position, null: false # Ordering 1..N
      t.string :question_type, null: false # 'mcq_single', 'mcq_multi', 'short_answer'
      t.text :prompt, null: false # Question text (markdown)
      t.jsonb :options, default: [] # Array of {key, text} for MCQ; empty for subjective
      t.jsonb :correct_answer # MCQ: array of correct option keys; subjective: model answer/rubric
      t.float :points, default: 1.0, null: false
      t.text :explanation # Shown post-grade

      t.timestamps
    end
  end
end
