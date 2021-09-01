module EasyVue
  module EasyQueryButtonsHelperPatch
    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :easy_issue_query_additional_ending_buttons, :easy_vue
      end
    end

    module InstanceMethods

      def easy_issue_query_additional_ending_buttons_with_easy_vue(issue, options = {})
        s = ActiveSupport::SafeBuffer.new
        s << easy_issue_query_additional_ending_buttons_without_easy_vue(issue, options)
        s << link_to(content_tag(:span, l(:label_open_modal_window), class: 'tooltip'), "javascript:void(0)", class: 'icon icon-view-modal', onclick: "EasyVue.showModal('scroll', #{issue.id})", title: l(:label_open_modal_window))
        s
      end
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper',
                                                      'EasyVue::EasyQueryButtonsHelperPatch',
                                                      if: proc { Redmine::Plugin.installed? :easy_extensions }
