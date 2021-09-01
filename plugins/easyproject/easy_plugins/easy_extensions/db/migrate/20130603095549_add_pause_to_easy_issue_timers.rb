class AddPauseToEasyIssueTimers < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_issue_timers, :pause, :decimal, :default => 0
    add_column :easy_issue_timers, :paused_at, :datetime
  end

  def self.down
  end

end
