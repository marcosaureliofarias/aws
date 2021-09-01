class RemoveArtefactIdFromReRelationshipVisualizations < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :re_relationship_visualizations, "artefakt_id"
  end

  def self.down
    add_column :re_relationship_visualizations, "artefakt_id", :integer
  end
end
