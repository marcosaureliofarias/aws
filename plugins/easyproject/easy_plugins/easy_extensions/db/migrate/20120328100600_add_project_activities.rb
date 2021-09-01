class AddProjectActivities < ActiveRecord::Migration[5.2]
  def change

    create_table :projects_activities, primary_key: %i[project_id activity_id] do |t|
      t.belongs_to :project
      t.belongs_to :activity
    end

  end

end
