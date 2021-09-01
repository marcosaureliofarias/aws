class AddCurrentVersionToReArtifactProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :re_artifact_properties, :current_version, :integer
  end
end
