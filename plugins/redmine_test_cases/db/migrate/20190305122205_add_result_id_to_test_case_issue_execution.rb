class AddResultIdToTestCaseIssueExecution < ActiveRecord::Migration[5.2]
  def change
    add_column :test_case_issue_executions, :result_id, :integer, null: true
    add_index :test_case_issue_executions, :result_id
  end
end
