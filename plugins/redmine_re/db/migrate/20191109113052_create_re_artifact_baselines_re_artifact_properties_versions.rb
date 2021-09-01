class CreateReArtifactBaselinesReArtifactPropertiesVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :re_artifact_baselines_re_artifact_properties_versions do |t|
      t.references :re_artifact_baseline, index: { name: 'rab_rav_on_rab_id' }
      t.references :re_artifact_properties_version, index: { name: 'rab_rav_on_rapv_id' }
      t.timestamps
    end
  end
end
