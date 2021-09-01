class AddProjectPrepaidHoursRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create!(:name => 'helpdesk_monitor_prepaid_hours', :context_id => AlertContext.named('helpdesk').first.id, :class_name => 'EasyAlerts::Rules::HelpdeskMonitorPrepaidHours')
  end

  def self.down
  end

end