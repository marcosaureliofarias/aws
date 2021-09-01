class AddHelpdeskSlaHoursToResolveRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create!(:name => 'helpdesk_monitor_hours_to_response', :context_id => AlertContext.named('helpdesk').first.id, :class_name => 'EasyAlerts::Rules::HelpdeskMonitorHoursToResponse')
  end

  def self.down
  end

end