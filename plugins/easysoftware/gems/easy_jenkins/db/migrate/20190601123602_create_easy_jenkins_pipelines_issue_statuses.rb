class CreateEasyJenkinsPipelinesIssueStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_pipelines_issue_statuses do |t|
      t.references :easy_jenkins_pipeline, index: { name: 'es_jenkins_ppln_id_on_ind_iss_sts_id' }
      t.references :issue_status, index: { name: 'ind_iss_sts_id_on_es_jenkins_ppln_id' }
      t.timestamps
    end
  end
end
