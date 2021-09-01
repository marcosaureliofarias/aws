class CreateEasyJenkinsJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_jobs do |t|
      t.references :easy_jenkins_pipeline, index: true
      t.integer :state, default: 0
      t.text :result
      t.float :duration
      t.integer :queue_id
      t.timestamps
    end
  end
end
