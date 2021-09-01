class CreateReArtifactPropertiesVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :re_artifact_properties_versions do |t|
      t.integer :version, null: false
      t.references :re_artifact_properties, index: { name: 'rapv_on_rap_id' }
      t.references :user, index: true
      t.string :artifact_type
      t.integer :project_id
      t.integer :parent_id
      t.integer :re_status_id
      t.integer :responsible_id
      t.string :name
      t.text :description
      t.text :acceptance_criteria
      t.text :issue_ids
      t.text :dependency_ids
      t.text :conflict_ids
      t.text :attachment_ids
      t.text :diagram_ids
      t.text :source_relationships
      t.text :sink_relationships
      t.text :custom_fields
      t.timestamps
    end
  end
end