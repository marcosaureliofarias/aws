class AddApprovalRequiredToEasyAttendanceActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendance_activities, :approval_required, :boolean, default: false
  end
end
