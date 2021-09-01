require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ReRelationshipTest < ActiveSupport::TestCase
  fixtures :projects
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
    [:re_artifact_relationships, :re_goals, :re_tasks, :re_subtasks, :re_artifact_properties])

  # def setup
  #     @last_child_position = 15
  #     @children = []
  #   end
  # 
  #   def test_parent_child
  #     project = Project.find(4)
  #     project_artifact = ReArtifactProperties.find( ActiveRecord::Fixtures.identify(:art_project) )
  #     project_artifact_id = project_artifact.id
  #     existing_parent_child_relations_count = project_artifact.child_relations.count    
  #     for i in 1..@last_child_position do
  #       child = ReSection.new( :name => "section #{i.to_s}" )
  #       child.project = project
  #       child.parent = project_artifact
  #       assert(child.save, "artifact should be saved")
  #       assert_equal(i + existing_parent_child_relations_count, child.parent_relation.position, "children position should increment")
  #       @children << child
  #     end
  # 
  #     assert_equal(@last_child_position + existing_parent_child_relations_count, ReArtifactRelationship.find_all_by_source_id_and_relation_type(project_artifact_id, "parentchild").size, "check if no fixtures created a relation accedentially")
  # 
  #     destroy_by_position(3)
  # 
  #     relations = ReArtifactRelationship.find_all_by_source_id_and_relation_type(project_artifact_id, "parentchild", :order => :position)
  #     relations.each_with_index do |r,i|
  #       logger.debug("#{self} ######### #{r.position} <--> #{i+1}")
  #     end
  #     assert_equal(@last_child_position + existing_parent_child_relations_count, relations.last.position , "last index should decrement by one deletion")
  # 
  #     relations.each_with_index do |r,i|
  #       assert_equal( r.position, i+1, "relations positions should be corrected")
  #     end
  # 
  #     destroy_by_position(3)
  #     destroy_by_position(6)
  #     destroy_by_position(2)
  # 
  #     relations = ReArtifactRelationship.find_all_by_source_id_and_relation_type(project_artifact_id, "parentchild", :order => :position)
  #     relations.each_with_index do |r,i|
  #       logger.debug("#{self} ######### #{r.position} <--> #{i+1}")
  #     end
  #     assert_equal(@last_child_position + existing_parent_child_relations_count, relations.last.position , "last index should decrement by three deletions")
  # 
  #     relations.each_with_index do |r,i|
  #       assert_equal( r.position, i+1, "relation positions should be corrected")
  #     end
  #   end
  # 
  #   def destroy_by_position(position)
  #     @children[position].re_artifact_properties.destroy
  #     @children.delete_at(position)
  #     @last_child_position -= 1
  #   end
  # 
  #   def test_moving_artifacts_parent_child
  #     project = Project.find(4)
  #     project_artifact = ReArtifactProperties.find( ActiveRecord::Fixtures.identify(:art_project) )
  #     project_artifact_id = project_artifact.id
  #     existing_parent_child_relations_count = project_artifact.child_relations.count
  #     for i in 1..@last_child_position do
  #       child = ReSection.new( :name => "level 1 section #{i.to_s}" )
  #       child.project = project
  #       child.parent = project_artifact
  #       assert(child.save, "artifact should be saved") 
  #       assert_equal(i + existing_parent_child_relations_count, child.parent_relation.position, "children position should increment")
  #       @children << child
  # 
  #       for j in 1..@last_child_position do
  #         child_child = ReSection.new( :name => "level 2 section #{i.to_s},#{j.to_s}" )
  #         child_child.project = project
  #         child_child.parent = child
  #         saved  = child_child.save
  #         assert(saved, "artifact should be saved")
  #         logger.debug("#{self} ######### child_child_relation: #{child_child.parent_relation.errors.inspect}")
  #         assert_equal(j, child_child.parent_relation.position, "children position should increment")
  #       end
  #     end
  # 
  #     moveme = ReArtifactProperties.find_by_name("level 2 section 2,5")
  #     movemes_old_pos = moveme.parent_relation.position
  #     assert_not_nil(moveme, "we just added this section")
  # 
  #     last_position = project_artifact.child_relations.last.position
  #     moveme.parent_relation.remove_from_list
  #     moveme.parent = project_artifact
  #     moveme.parent_relation.insert_at(last_position + 1)
  # 
  #     for i in movemes_old_pos..@last_child_position-1 do
  #       assert_equal(i, ReArtifactProperties.find_by_name("level 2 section 2,#{i+1}").parent_relation.position, "movemes lover siblings should be corrected")
  #     end
  # 
  #     assert_equal(@last_child_position + 1 + existing_parent_child_relations_count, moveme.parent_relation.position, "moveme should be added to the end of the list of its new siblings")
  #   end

end
