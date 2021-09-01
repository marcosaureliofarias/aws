class AddTimeentryTimeWatcherPreviousDayRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create :name => "timeentry_time_watcher_previous_period", :context_id => AlertContext.named('timeentry').first.id, :class_name => "EasyAlerts::Rules::TimeEntryTimeWatcherPreviousPeriod", :position => 7
  end

  def self.down
  end

end
