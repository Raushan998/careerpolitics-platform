class AddIndexesToMockTestQuestions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :mock_test_questions,
              %i[mock_test_session_id position],
              unique: true,
              algorithm: :concurrently
  end
end
