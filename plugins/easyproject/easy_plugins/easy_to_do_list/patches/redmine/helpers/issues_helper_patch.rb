module EasyToDoListModule
  module IssuesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # alias_method_chain :easy_issue_query_additional_ending_buttons, :easy_to_do_list
        # alias_method_chain :heading_issue, :easy_to_do_list

      end
    end

    module InstanceMethods

      def easy_issue_query_additional_ending_buttons_with_easy_to_do_list(issue, options = {})
        s = easy_issue_query_additional_ending_buttons_without_easy_to_do_list(issue, options) || ''
        s << easy_to_do_list_source_handle_tag(issue) unless is_mobile_device?

        return s.html_safe
      end

      def heading_issue_with_easy_to_do_list(issue)
        content_tag(:h2, (h(issue) + easy_to_do_list_source_handle_tag(issue)).html_safe, :class => 'issue-detail-header easy-to-do-list-source')
      end

    end

  end

end
# EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyToDoListModule::IssuesHelperPatch'
