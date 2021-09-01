class AddIndexToEasyHelpdeskProjectsProjectId < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_helpdesk_projects, :project_id unless index_exists?(:easy_helpdesk_projects, :project_id)
  end

  def down
  end
end