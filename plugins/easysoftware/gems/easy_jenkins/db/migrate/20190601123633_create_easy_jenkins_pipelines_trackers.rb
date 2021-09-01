class CreateEasyJenkinsPipelinesTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_jenkins_pipelines_trackers do |t|
      t.references :easy_jenkins_pipeline, index: { name: 'es_jenkins_ppln_id_on_ind_iss_trk_id' }
      t.references :tracker, index: true
      t.timestamps
    end
  end
end
