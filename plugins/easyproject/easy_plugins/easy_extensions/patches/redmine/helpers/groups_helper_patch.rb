module EasyPatch
  module GroupsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :group_settings_tabs, :easy_extensions

      end
    end

    module InstanceMethods

      DESTROY_CONFIRMATION_MAX_PROJECTS_SHOWN = 5
      DESTROY_CONFIRMATION_MAX_USERS_SHOWN = 5

      def group_settings_tabs_with_easy_extensions(group)
        tabs = group_settings_tabs_without_easy_extensions(group)
        tabs << { :name => 'avatar', :partial => 'easy_avatars/avatar', :label => :label_avatar, :no_js_link => true, :entity => group }
        call_hook(:helper_group_settings_tabs, :group => group, :tabs => tabs)

        tabs.each { |t| t[:no_js_link] = true }
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'GroupsHelper', 'EasyPatch::GroupsHelperPatch'
