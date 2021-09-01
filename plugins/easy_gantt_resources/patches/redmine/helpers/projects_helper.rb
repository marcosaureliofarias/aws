module EasyGanttResources
  module ProjectsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :project_settings_tabs, :easy_gantt_resources
      end
    end

    module InstanceMethods

      def project_settings_tabs_with_easy_gantt_resources
        tabs = project_settings_tabs_without_easy_gantt_resources

        if User.current.admin?
          tabs << { name: 'easy_gantt_resources', partial: 'projects/settings/easy_gantt_resources', label: :label_easy_gantt_resources_settings, no_js_link: true }
        end

        tabs
      end

    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'ProjectsHelper', 'EasyGanttResources::ProjectsHelperPatch'
