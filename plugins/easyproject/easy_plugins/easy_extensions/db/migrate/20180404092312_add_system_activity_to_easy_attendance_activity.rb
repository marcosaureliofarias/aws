class AddSystemActivityToEasyAttendanceActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendance_activities, :system_activity, :boolean, default: false
  end
end
