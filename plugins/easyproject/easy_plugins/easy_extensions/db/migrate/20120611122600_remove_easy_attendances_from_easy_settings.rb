class RemoveEasyAttendancesFromEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.where(:name => 'easy_attendance_enabled').destroy_all
  end

  def self.down
  end
end