class AddUrlToEasyJenkinsJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_jenkins_jobs, :url, :string
  end
end
