class AddEasyPriorityIdToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :easy_priority_id, :integer, default: nil
  end
end
