module EasyQuickProjectPlanner
  module EasyAgileBoardHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :new_issue_tabs, :easy_quick_project_planner

      end
    end

    module InstanceMethods

      def new_issue_tabs_with_easy_quick_project_planner
        tabs = new_issue_tabs_without_easy_quick_project_planner || []

        if @project.module_enabled?('quick_planner')
          url = quick_planner_path(project_id: @project, issue: { easy_sprint_id: @easy_sprint }, for_dialog: true)
          tabs << { name: 'quick_planning', label: l(:label_quick_planning), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
        else
          tabs << { name: 'quick_planning', label: l(:label_quick_planning), trigger: 'EntityTabs.showTab(this)', partial: 'easy_quick_project_planner/quick_planner_inactive' }
        end

        tabs
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'EasyAgileBoardHelper', 'EasyQuickProjectPlanner::EasyAgileBoardHelperPatch', if: Proc.new { Redmine::Plugin.installed?(:easy_agile_board) }
