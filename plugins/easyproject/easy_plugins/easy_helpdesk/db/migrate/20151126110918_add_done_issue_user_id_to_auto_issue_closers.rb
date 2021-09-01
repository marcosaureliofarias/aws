class AddDoneIssueUserIdToAutoIssueClosers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_auto_issue_closers, :done_issue_user_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_auto_issue_closers, :done_issue_user_id
  end
end