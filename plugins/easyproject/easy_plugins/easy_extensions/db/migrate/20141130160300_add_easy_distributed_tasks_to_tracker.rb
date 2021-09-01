class AddEasyDistributedTasksToTracker < ActiveRecord::Migration[4.2]
  def self.up
    add_column :trackers, :easy_distributed_tasks, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :trackers, :easy_distributed_tasks
  end
end
