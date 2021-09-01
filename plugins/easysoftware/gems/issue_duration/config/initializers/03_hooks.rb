module IssueDuration
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, partial: 'issues/issue_easy_duration_field'
    render_on :view_issues_show_details_bottom, partial: 'issues/issue_easy_duration_attribute'
    render_on :view_issues_bulk_edit_details_bottom, partial: 'issues/issue_easy_duration_bulk_edit_fields'


    def controller_issues_bulk_edit_before_save(context = {})
      issue_params = context[:params][:issue] if context[:params]
      issue = context[:issue]

      if issue_params && issue_params[:easy_duration].present?
        if issue.start_date.present?
          issue.due_date = IssueEasyDuration.move_date(issue_params[:easy_duration], issue_params[:easy_duration_time_unit], issue.start_date, issue.due_date)
        elsif issue.due_date.present?
          issue.start_date = IssueEasyDuration.move_date(issue_params[:easy_duration], issue_params[:easy_duration_time_unit], issue.start_date, issue.due_date)
        end
      end
    end

  end
end
