class CreateExams < ActiveRecord::Migration[7.0]
  def change
    create_table :exams do |t|
      t.string :name, null: false
      t.string :slug, null: false # For friendly URLs, generated like JobPost
      t.text :description
      t.string :category
      t.text :syllabus_context # Curated context injected into the AI prompt
      t.integer :default_question_count, default: 20, null: false
      t.integer :default_duration_minutes, default: 30, null: false
      t.string :difficulty # 'easy', 'medium', 'hard'
      t.boolean :published, default: false, null: false
      t.integer :position, default: 0, null: false
      t.references :subforem, null: true, foreign_key: true # Multi-tenancy; nil = global

      t.timestamps
    end
  end
end
