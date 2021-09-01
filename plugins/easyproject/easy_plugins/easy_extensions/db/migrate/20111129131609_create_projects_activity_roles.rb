class CreateProjectsActivityRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :projects_activity_roles, primary_key: %i[project_id activity_id role_id] do |t|
      t.integer :project_id, index: true
      t.integer :activity_id
      t.integer :role_id

      t.index [:project_id, :role_id]
    end

  end

end
