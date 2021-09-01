class AddIssueStatusIdToEasySlaEvents < ActiveRecord::Migration[5.2]
  def up
    add_reference :easy_sla_events, :issue_status, null: true
  end

  def down
    remove_reference :easy_sla_events, :issue_status
  end
end
