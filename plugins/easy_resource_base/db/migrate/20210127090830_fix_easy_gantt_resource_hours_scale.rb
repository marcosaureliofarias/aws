class FixEasyGanttResourceHoursScale < ActiveRecord::Migration[5.2]
  def up
    change_column :easy_gantt_resources, :hours, :decimal, precision: 7, scale: 2, null: false
    change_column :easy_gantt_resources, :original_hours, :decimal, precision: 7, scale: 2, default: 0
  end
end
