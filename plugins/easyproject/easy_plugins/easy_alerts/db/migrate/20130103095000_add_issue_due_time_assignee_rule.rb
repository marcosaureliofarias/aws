class AddIssueDueTimeAssigneeRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create!(:name => 'helpdesk_monitor_due_time_assignee', :context_id => AlertContext.named('helpdesk').first.id, :class_name => 'EasyAlerts::Rules::HelpdeskMonitorDueTimeAssignee')
  end

  def self.down
  end

end