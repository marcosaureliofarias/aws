module EasyKnowledge
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_knowledge_stories
        include EasyKnowledgeStoriesHelper

        def easy_knowledge_stories
          @easy_knowledge_stories = EasyKnowledgeStory.find(params[:ids])
          @project = Project.find(params[:project_id]) if params[:project_id]

          @can = {
            user: User.current.allowed_to_globally?(:manage_own_personal_categories),
            global: User.current.allowed_to_globally?(:edit_all_global_stories),
            project: User.current.allowed_to?(:manage_project_stories, @project),
            :edit_own_global_stories => User.current.allowed_to_globally?(:edit_own_global_stories, {}),
            :edit_all_global_stories => User.current.allowed_to_globally?(:edit_all_global_stories, {}),
            :stories_assignment => User.current.allowed_to?(:stories_assignment, @project),
            :stories_assignment_global => User.current.allowed_to_globally?(:stories_assignment, {})
          }

          render :layout => false
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyKnowledge::ContextMenusControllerPatch'
