class AddOriginalHoursToEasyGanttResources < ActiveRecord::Migration[5.2]

  def up
    add_column :easy_gantt_resources, :original_hours, :decimal, precision: 6, scale: 1, default: 0
  end

  def down
    remove_column :easy_gantt_resources, :original_hours
  end

end
