class AddRatingAverageToReArtifactProperties < ActiveRecord::Migration[4.2]
  def self.up
    add_column :re_artifact_properties, :rating_average, :decimal, :default => 0, :precision => 6, :scale => 2
  end

  def self.down
    remove_column :re_artifact_properties, :rating_average
  end
end