class AddProjectIdToRakes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_rake_tasks, :project_id, :integer, { :null => true }
  end

  def self.down
    remove_column :easy_rake_tasks, :project_id
  end
end
