class AddTimezoneToEasyAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_attendances, :time_zone, :string, limit: 6
  end
end
