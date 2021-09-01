class MigrateOldIssueCloser < ActiveRecord::Migration[4.2]
  def up
    if column_exists?(:easy_helpdesk_projects, :automatically_issue_closer_enable)
      EasyHelpdeskProject.where(:automatically_issue_closer_enable => true).each do |ehp|
        EasyHelpdeskAutoIssueCloser.create({
           :easy_helpdesk_project => ehp,
           :observe_issue_status_id => ehp.issue_closer_observe_issue_status_id,
           :done_issue_status_id => ehp.issue_closer_done_issue_status_id,
           :inactive_interval => ehp.issue_closer_inactive_interval,
           :inactive_interval_unit => EasyHelpdeskAutoIssueCloser.inactive_interval_units[ehp.issue_closer_inactive_interval_unit].to_i
                                           })
      end
    end
  end

  def down
    # Nothing to do
  end
end
