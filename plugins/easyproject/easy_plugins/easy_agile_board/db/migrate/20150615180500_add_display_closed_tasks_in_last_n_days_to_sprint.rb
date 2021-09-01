class AddDisplayClosedTasksInLastNDaysToSprint < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_sprints, :display_closed_tasks_in_last_n_days, :integer, {:null => true, :default => nil}
  end
end
