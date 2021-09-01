class AddApprovalStatusToEasyAttendance < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendances, :approval_status, :integer, default: nil
  end
end
