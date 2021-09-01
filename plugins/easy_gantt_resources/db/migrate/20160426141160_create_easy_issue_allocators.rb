class CreateEasyIssueAllocators < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_issue_allocators do |t|
      t.integer :issue_id
      t.string :allocator, null: false
    end
  end
end
