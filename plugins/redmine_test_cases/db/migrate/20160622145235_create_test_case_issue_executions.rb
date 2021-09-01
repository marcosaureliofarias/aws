class CreateTestCaseIssueExecutions < ActiveRecord::Migration[4.2]
  def change
    create_table :test_case_issue_executions, force: true do |t|
      t.references :test_case, null: true
      t.references :issue, null: true
      t.integer :result, null: true
      t.references :author, null: false
      t.text :comments, null: true

      t.timestamps null: false
    end
  end
end
