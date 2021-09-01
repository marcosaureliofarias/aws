class AddIsDefaultForNewProjectsToEasyChecklists < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_checklists, :is_default_for_new_projects, :boolean, default: false
  end

  def down
    remove_column :easy_checklists, :is_default_for_new_projects
  end
end
