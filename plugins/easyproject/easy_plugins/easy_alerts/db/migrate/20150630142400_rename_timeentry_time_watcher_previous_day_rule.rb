class RenameTimeentryTimeWatcherPreviousDayRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.where(:name => 'timeentry_time_watcher_previous_day').update_all(:name => 'timeentry_time_watcher_previous_period', :class_name => "EasyAlerts::Rules::TimeEntryTimeWatcherPreviousPeriod")
  end

  def self.down
  end

end
