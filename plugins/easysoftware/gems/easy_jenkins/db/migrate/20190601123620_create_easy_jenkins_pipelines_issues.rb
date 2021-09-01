class CreateEasyJenkinsPipelinesIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_pipelines_issues do |t|
      t.references :easy_jenkins_pipeline, index: true
      t.references :issue, index: true
      t.timestamps
    end
  end
end
