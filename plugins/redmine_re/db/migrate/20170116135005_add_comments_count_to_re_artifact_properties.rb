class AddCommentsCountToReArtifactProperties < ActiveRecord::Migration[4.2]
  def change
  	add_column :re_artifact_properties, :comments_count, :integer, default: 0
  end
end
