module EasyQuickProjectPlanner
  module ProjectsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :settings, :easy_quick_project_planner
      end
    end

    module InstanceMethods

      def settings_with_easy_quick_project_planner
        settings_without_easy_quick_project_planner
        @easy_quick_planner_fields = EasySetting.value(:quick_planner_fields, @project)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ProjectsController', 'EasyQuickProjectPlanner::ProjectsControllerPatch'
