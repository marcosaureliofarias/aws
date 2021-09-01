class CreateEasyJenkinsPipelines < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_pipelines do |t|
      t.references :easy_jenkins_setting, index: true
      t.boolean :for_all_tasks
      t.timestamps
    end
  end
end
