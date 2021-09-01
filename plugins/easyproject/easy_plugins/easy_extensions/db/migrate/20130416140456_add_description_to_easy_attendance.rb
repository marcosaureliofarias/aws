class AddDescriptionToEasyAttendance < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendances, :description, :text
  end
end
