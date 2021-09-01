module RedmineTestCases
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_issues_sidebar_issues_bottom, :partial => 'test_cases/issue_menu'
    render_on :view_issue_sidebar_issue_buttons, :partial => 'test_cases/issue_menu'
    render_on :view_issues_show_description_bottom, :partial => 'test_cases/issue_test_cases'
    render_on :view_issues_form_details_bottom, :partial => 'test_cases/issue_form_test_cases'

    def model_project_copy_additionals(context={})
      context[:to_be_copied] << 'test_cases'
    end
  end
end
