class NewRules2 < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create :name => "project_due_date", :context_id => AlertContext.named('project').first.id, :class_name => "EasyAlerts::Rules::ProjectDueDate", :position => 1
    AlertRule.create :name => "version_due_date", :context_id => AlertContext.named('milestone').first.id, :class_name => "EasyAlerts::Rules::VersionDueDate", :position => 2
    AlertRule.create :name => "issue_updated_date", :context_id => AlertContext.named('issue').first.id, :class_name => "EasyAlerts::Rules::IssueUpdatedDate", :position => 3
    AlertRule.create :name => "issue_due_date", :context_id => AlertContext.named('issue').first.id, :class_name => "EasyAlerts::Rules::IssueDueDate", :position => 4
    AlertRule.create :name => "easy_issue_query", :context_id => AlertContext.named('issue').first.id, :class_name => "EasyAlerts::Rules::EasyIssueQuery", :position => 5
    AlertRule.create :name => "timeentry_time_watcher", :context_id => AlertContext.named('timeentry').first.id, :class_name => "EasyAlerts::Rules::TimeEntryTimeWatcher", :position => 6
  end

  def self.down
  end
end