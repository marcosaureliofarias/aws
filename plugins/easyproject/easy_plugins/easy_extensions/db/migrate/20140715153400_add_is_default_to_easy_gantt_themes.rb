class AddIsDefaultToEasyGanttThemes < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_gantt_themes, :is_default, :boolean, :default => false, :null => false
  end

  def down
    remove_column :easy_gantt_themes, :is_default
  end

end
