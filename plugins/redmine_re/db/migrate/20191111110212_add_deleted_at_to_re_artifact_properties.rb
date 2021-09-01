class AddDeletedAtToReArtifactProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :re_artifact_properties, :deleted_at, :datetime
    add_index :re_artifact_properties, :deleted_at
  end
end
