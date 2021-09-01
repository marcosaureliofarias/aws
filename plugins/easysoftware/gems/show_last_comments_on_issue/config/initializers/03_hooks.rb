# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module ShowLastCommentsOnIssue
  class Hooks < ::Redmine::Hook::ViewListener

    def view_issues_show_details_bottom(context = {})
      context[:hook_caller].render partial: 'issues/show_last_comments_on_issue/view_issues_show_details_bottom', locals: {issue: context[:issue]} if Rys::Feature.active?('show_last_comments_on_issue.show')
    end

    def view_issue_settings_display(context = {})
      if ShowLastCommentsOnIssue.show_settings?
        context[:hook_caller].render partial: 'settings/show_issue_last_comments_limit_easy_settings'
      end
    end

  end
end
