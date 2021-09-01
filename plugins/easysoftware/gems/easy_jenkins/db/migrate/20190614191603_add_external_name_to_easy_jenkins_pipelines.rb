class AddExternalNameToEasyJenkinsPipelines < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_jenkins_pipelines, :external_name, :string
  end
end
