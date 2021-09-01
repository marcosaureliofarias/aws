class CreateEasyHelpdeskAutoIssueCloser < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_helpdesk_auto_issue_closers do |t|
      t.belongs_to :easy_helpdesk_project
      t.integer :observe_issue_status_id
      t.integer :done_issue_status_id

      t.decimal :inactive_interval, :precision => 8, :scale => 2, :null => true
      t.integer :inactive_interval_unit, :default => 0

      t.timestamps :null => false
    end
  end

  def down
    drop_table :easy_helpdesk_auto_issue_closers
  end
end
