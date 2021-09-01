class AddProjectToEasyJenkinsSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_jenkins_settings, :project_id, :integer
  end
end
