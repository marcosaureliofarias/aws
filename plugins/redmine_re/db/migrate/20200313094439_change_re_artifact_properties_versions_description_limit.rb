class ChangeReArtifactPropertiesVersionsDescriptionLimit < ActiveRecord::Migration[5.2]
  def up
    change_column :re_artifact_properties_versions, :description, :text, limit: 16.megabytes
  end
end
