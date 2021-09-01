module RedmineRe
  module ProjectControllerPatch
    def self.included(base)
      base.class_eval do
        alias_method :update_without_requirement_project_name_update, :update unless method_defined?(:update_without_requirement_project_name_update)
        alias_method :update, :update_with_requirement_project_name_update

        alias_method :create_without_added_relationtypes, :create unless method_defined?(:create_without_added_relationtypes)
        alias_method :create, :create_with_added_relationtypes
      end
    end

    def update_with_requirement_project_name_update
      # Perform update action
      update_without_requirement_project_name_update

      # Update project name
      artifact = ReArtifactProperties.find_by(artifact_type: 'Project', project_id: @project.id)

      if !artifact.nil?
        #restrict file name length to allowed length in artifact name
        name = @project.name
        length = name.length
        if length < 3
          name = "#{name} Project"
        elsif name.length > 50
          name = name.slice(0, 50)
        end
        artifact.update_attribute(:name, name)
      end

    end

    def create_with_added_relationtypes

      create_without_added_relationtypes

      # GET OLD PROJECT NAME
      unless @project&.new_record?
        ReRelationtype.create(:project_id => @project.id, :relation_type => "parentchild",   :alias_name => "parentchild",  :color => "#0000ff", :is_system_relation => true,  :is_directed => true,  :in_use => true)
        ReRelationtype.create(:project_id => @project.id, :relation_type => "dependency",    :alias_name => "dependency",    :color => "#339966", :is_system_relation => false, :is_directed => true,  :in_use => true)
        ReRelationtype.create(:project_id => @project.id, :relation_type => "conflict",      :alias_name => "conflict",      :color => "#ff0000", :is_system_relation => false, :is_directed => false, :in_use => true)
      end
    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'ProjectsController', 'RedmineRe::ProjectControllerPatch'