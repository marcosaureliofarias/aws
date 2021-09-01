class AddRangeToEasyAttendances < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendances, :range, :integer
  end
end
