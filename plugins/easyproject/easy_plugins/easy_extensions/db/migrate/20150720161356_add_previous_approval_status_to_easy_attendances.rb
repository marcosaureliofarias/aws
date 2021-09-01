class AddPreviousApprovalStatusToEasyAttendances < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendances, :previous_approval_status, :integer, :limit => 1, :default => nil
  end
end
