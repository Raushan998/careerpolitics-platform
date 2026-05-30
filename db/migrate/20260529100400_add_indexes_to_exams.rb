class AddIndexesToExams < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :exams, %i[slug subforem_id], unique: true, algorithm: :concurrently
    add_index :exams,
              %i[published subforem_id position],
              where: "published = true",
              name: "index_exams_on_published_query",
              algorithm: :concurrently
  end
end
