class CreateEasyJenkinsJobsIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_jobs_issues do |t|
      t.references :easy_jenkins_job, index: true
      t.references :issue, index: true
      t.timestamps
    end
  end
end
