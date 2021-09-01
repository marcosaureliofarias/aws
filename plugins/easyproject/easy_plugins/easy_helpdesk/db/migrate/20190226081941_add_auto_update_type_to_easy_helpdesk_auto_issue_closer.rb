class AddAutoUpdateTypeToEasyHelpdeskAutoIssueCloser < ActiveRecord::Migration[5.2]
  def self.up
    add_column :easy_helpdesk_auto_issue_closers, :auto_update_modes, :text
    add_column :easy_helpdesk_auto_issue_closers, :easy_helpdesk_mail_template_id, :integer
  end

  def self.down
    remove_column :easy_helpdesk_auto_issue_closers, :auto_update_modes
    remove_column :easy_helpdesk_auto_issue_closers, :easy_helpdesk_mail_template_id
  end
end
