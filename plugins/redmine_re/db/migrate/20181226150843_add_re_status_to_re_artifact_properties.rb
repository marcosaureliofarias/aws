class AddReStatusToReArtifactProperties < ActiveRecord::Migration[4.2]
  def change
    add_column :re_artifact_properties, :re_status_id, :integer, index: true
  end
end
