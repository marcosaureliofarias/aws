class AddIssueDueTimeManagerRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create!(:name => 'helpdesk_monitor_due_time_manager', :context_id => AlertContext.named('helpdesk').first.id, :class_name => 'EasyAlerts::Rules::HelpdeskMonitorDueTimeManager')
  end

  def self.down
  end

end