module EasyGanttResources
  module ApplicationHelperPatch

    def self.included(base)

      base.class_eval do

        def get_epm_easy_gantt_resources_toggling_container_options(page_module, options = {})
          tc_options = {}
          if !options[:edit] && User.current.admin? && @project.nil?
            plugin = Redmine::Plugin.find('easy_gantt_resources')
            tc_options[:heading_links] = link_to('', plugin_settings_path(plugin, back_url: Addressable::URI.unescape(request.fullpath)), class: 'icon icon-settings', title: l(:label_easy_gantt_resources_settings))
          end
          tc_options
        end

      end
    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyGanttResources::ApplicationHelperPatch'
