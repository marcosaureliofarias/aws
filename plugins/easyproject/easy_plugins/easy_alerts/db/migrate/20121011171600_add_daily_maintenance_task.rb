class AddDailyMaintenanceTask < ActiveRecord::Migration[4.2]

  def self.up
    EasyRakeTaskAlertDailyMaintenance.reset_column_information
    t = EasyRakeTaskAlertDailyMaintenance.new(:active => true, :settings => {}, :period => :minutes, :interval => 15, :next_run_at => Time.now)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskAlertDailyMaintenance.destroy_all
  end

end