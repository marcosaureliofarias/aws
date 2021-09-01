require 'easy_extensions/spec_helper'

describe 'rules', logged: :admin do
  let(:alert_context) { FactoryBot.create(:alert_context) }
  let(:alert_rule) { AlertRule.create :name => 'issue_due_date', :class_name => 'EasyAlerts::Rules::IssueDueDate', :context_id => alert_context.id }
  let(:alert) { FactoryBot.create(:alert, rule: alert_rule, rule_settings: {date_type: 'date', date: Date.today}) }

  it 'issue due date' do
    expect(EasyAlerts::Rules::IssueDueDate.new.find_items(alert).count).to eq(0)
  end

  context '"active project only" option' do
    let(:date) { Date.today }
    let(:project_active) { FactoryBot.create(:project, status: Project::STATUS_ACTIVE ) }
    let(:project_closed) { FactoryBot.create(:project, status: Project::STATUS_CLOSED ) }
    let!(:issue_active_project) { FactoryBot.create(:issue, project: project_active, start_date: date.yesterday, due_date: date) }
    let!(:issue_closed_project) { FactoryBot.create(:issue, project: project_closed, start_date: date.yesterday, due_date: date) }
    let(:alert_active_projects_only) { FactoryBot.create(:alert, rule: alert_rule, rule_settings: {date_type: 'date', date: date}, active_projects_only: true) }
    let(:alert_all_projects) { FactoryBot.create(:alert, rule: alert_rule, rule_settings: {date_type: 'date', date: date}, active_projects_only: false) }

    it 'covers active projects only when enabled' do
      alert_rule = EasyAlerts::Rules::IssueDueDate.new
      alert_rule.initialize_from_alert(alert_active_projects_only)
      expect(alert_rule.find_items(alert_active_projects_only)).to include(issue_active_project)
      expect(alert_rule.find_items(alert_active_projects_only)).not_to include(issue_closed_project)
    end

    it 'covers all projects when disabled' do
      alert_rule = EasyAlerts::Rules::IssueDueDate.new
      alert_rule.initialize_from_alert(alert_all_projects)
      expect(alert_rule.find_items(alert_all_projects)).to include(issue_active_project)
      expect(alert_rule.find_items(alert_all_projects)).to include(issue_closed_project)
    end
  end
end
