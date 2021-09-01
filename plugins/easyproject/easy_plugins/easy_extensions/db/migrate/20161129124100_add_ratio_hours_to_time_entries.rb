class AddRatioHoursToTimeEntries < ActiveRecord::Migration[4.2]
  def change
    add_column :time_entries, :easy_divided_hours, :float, { default: 0.0, null: false }
  end
end
