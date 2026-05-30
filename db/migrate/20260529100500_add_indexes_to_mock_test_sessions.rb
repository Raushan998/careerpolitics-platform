class AddIndexesToMockTestSessions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :mock_test_sessions, %i[user_id created_at], algorithm: :concurrently
    add_index :mock_test_sessions, :status, algorithm: :concurrently
  end
end
