module EasyEarnedValues
  module ProjectsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :project_settings_tabs, :easy_earned_values
      end
    end

    module InstanceMethods

      def project_settings_tabs_with_easy_earned_values
        tabs = project_settings_tabs_without_easy_earned_values

        if User.current.allowed_to?(:edit_easy_earned_values, @project)
          tabs << { name: 'easy_earned_values', partial: 'projects/settings/easy_earned_values', label: :label_easy_earned_values, no_js_link: true }
        end

        tabs
      end

    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'ProjectsHelper', 'EasyEarnedValues::ProjectsHelperPatch'
