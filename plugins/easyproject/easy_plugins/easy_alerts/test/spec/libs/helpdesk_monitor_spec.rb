require 'easy_extensions/spec_helper'

describe 'helpdesk monitor', logged: :admin, skip: !Redmine::Plugin.installed?(:easy_helpdesk) do
  let(:alert_context) { FactoryBot.create(:alert_context) }
  let(:alert_rule) { AlertRule.create name: 'helpdesk_monitor_hours_to_response', class_name: 'EasyAlerts::Rules::HelpdeskMonitorHoursToResponse', context_id: alert_context.id }
  let(:alert) { FactoryBot.create(:alert, rule: alert_rule, rule_settings: {date_type: 'date', date: Date.today, percentage: 0}) }

  it 'without sla' do
    alert_rule = EasyAlerts::Rules::HelpdeskMonitorHoursToResponse.new
    alert_rule.initialize_from_alert(alert)
    expect(alert_rule.find_items(alert).count).to eq(0)
  end

  context 'with sla' do
    let(:sla) { FactoryBot.create(:easy_helpdesk_project_sla, hours_to_response: 1) }
    let(:issue) { FactoryBot.create(:issue, project: sla.easy_helpdesk_project.project, priority: sla.priority ) }

    it 'with hours to response' do
      issue
      alert_rule = EasyAlerts::Rules::HelpdeskMonitorHoursToResponse.new
      alert_rule.initialize_from_alert(alert)
      expect(alert_rule.find_items(alert).count).to eq(1)
    end

    context 'without hours to response' do
      let(:sla) { FactoryBot.create(:easy_helpdesk_project_sla, hours_to_response: nil) }

      it do
        issue
        alert_rule = EasyAlerts::Rules::HelpdeskMonitorHoursToResponse.new
        alert_rule.initialize_from_alert(alert)
        expect(alert_rule.find_items(alert).count).to eq(0)
      end
    end
  end
end
