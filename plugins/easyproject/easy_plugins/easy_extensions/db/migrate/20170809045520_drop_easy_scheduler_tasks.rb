class DropEasySchedulerTasks < ActiveRecord::Migration[4.2]
  def up
    drop_table :easy_scheduler_tasks if table_exists?(:easy_scheduler_tasks)
  end

  def down
  end
end
