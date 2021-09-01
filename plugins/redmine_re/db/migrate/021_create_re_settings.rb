class CreateReSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :re_settings do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "value", :text
      t.column "project_id", :integer, :null => false
      t.column "updated_on", :timestamp
    end

    remove_column :re_artifact_relationships, "directed"

    relations_types = {
      1 => 'parentchild',
      2 => 'dependency',
      3 => 'conflict',
      4 => 'rationale',
      5 => 'refinement',
      6 => 'part_of'
    }

    stored_relations = {}
    ReArtifactRelationship.all.each do |rel|
      #print 'storing {' + rel.id.to_s + ' => ' + rel.relation_type.to_s + '} \n'
      stored_relations[rel.id] = rel.relation_type
    end
    change_column(:re_artifact_relationships, :relation_type, :string, :limit => 50, :null => false, :default => 'parentchild')
    ReArtifactRelationship.reset_column_information
    #print 'relations: ' + stored_relations.inspect

    ReArtifactRelationship.all.each do |rel|
      new_type = relations_types[stored_relations[rel.id]].to_s
      say "changing int representation " + stored_relations[rel.id].to_s + " for relation " + rel.id.to_s
      say "to string: " + new_type, true
      rel.update_attribute("relation_type", new_type)
    end
  end

  def self.down

    if table_exists?(:re_settings)
      drop_table :re_settings
    end

    unless column_exists?(:re_artifact_relationships, :directed)
      add_column :re_artifact_relationships, "directed", :boolean
    end

    relations_types = {
      'parentchild' => 1,
      'dependency' => 2,
      'conflict' => 3,
      'rationale' => 4,
      'refinement' => 5,
      'part_of' => 6
    }

    stored_relations = {}
    ReArtifactRelationship.all.each do |rel|
      stored_relations[rel.id] = rel.relation_type
    end
    # doesn't work on pg
    #change_column :re_artifact_relationships, :relation_type, :integer, :null => false, :default => 0
    ReArtifactRelationship.reset_column_information

  end
end
