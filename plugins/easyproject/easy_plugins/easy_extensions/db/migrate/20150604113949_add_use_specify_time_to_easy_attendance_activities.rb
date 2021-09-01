class AddUseSpecifyTimeToEasyAttendanceActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendance_activities, :use_specify_time, :boolean, :default => nil, :null => true
  end
end
