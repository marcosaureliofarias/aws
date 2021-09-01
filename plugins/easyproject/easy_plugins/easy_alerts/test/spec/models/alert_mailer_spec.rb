require 'easy_extensions/spec_helper'

describe AlertMailer, logged: :admin do

  let(:alert_context) { FactoryGirl.create(:alert_context) }
  let(:alert_rule) { AlertRule.create :name => "easy_issue_query", :class_name => "EasyAlerts::Rules::EasyIssueQuery", :context_id => alert_context.id }
  let(:easy_issue_query) {
    FactoryGirl.create(:easy_issue_query, :column_names =>
        [
         :project, :subject, :assigned_to, :due_date, :done_ratio,
         :main_project, :parent, :status, :tracker, :priority, :author,
         :fixed_version, :start_date, :created_on, :updated_on, :easy_status_updated_on,
         :open_duration_in_hours, :parent_category, :root_category, :parent_project,
         :estimated_hours, :sum_of_timeentries, :remaining_timeentries, :spent_estimated_timeentries,
         :watchers, :relations, :description, :attachments, :easy_due_date_time,
         :closed_on, :easy_closed_by, :is_private, :category, :status_time_current,
         :status_time_1, :status_count_1, :"issue_easy_sprint_relation.easy_sprint",
         :easy_response_date_time, :easy_helpdesk_project_monthly_hours,
         :easy_helpdesk_mailbox_username, :easy_crm_client_zone_token
       ]
      )
  }
  let(:alert) {
    FactoryGirl.create(:alert, rule: alert_rule, rule_settings: {:query_id => easy_issue_query.id, :entity_count => 0})
  }
  let(:issues) {
    FactoryGirl.create_list(:issue, 2)
  }

  it 'sends mails with query correctly' do
    alert
    issues
    EasyRakeTaskAlertDailyMaintenance.new.execute

    last_mail_body = ActionMailer::Base.deliveries.last.html_part.body
    issues.each do |issue|
      expect(last_mail_body).to include("<span>#{issue.assigned_to}</span>")
      expect(last_mail_body).to_not include("<span data-type=easy_autocomplete><span>#{issue.assigned_to}</span></span>")
    end
    expect(last_mail_body).to_not include('input')
  end

end
