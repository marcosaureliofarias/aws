class AddIndexParentIdToProjects < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :parent_id, :name => 'idx_projects_parent_id'
  end
end
