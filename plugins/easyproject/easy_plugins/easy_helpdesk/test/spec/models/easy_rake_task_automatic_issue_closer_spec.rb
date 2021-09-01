require 'easy_extensions/spec_helper'

RSpec.describe EasyRakeTaskEasyHelpdeskIssueCloserAutomat, '#execute' do
  let(:automat) { described_class.new }
  let(:helpdesk_project) { FactoryBot.create(:easy_helpdesk_project) }
  let(:status_observer) { FactoryBot.create(:issue_status) }
  let(:status) { FactoryBot.create(:issue_status, :closed) }
  let!(:issues) { FactoryBot.create_list(:issue, 3, project: helpdesk_project.project, status: status_observer ) }
  let(:options) {
    {
      observe_issue_status_id: status_observer.id,
      inactive_interval: 5,
      inactive_interval_unit: 1,
      done_issue_status_id: status.id,
      done_issue_user_id: User.current.id
    }
  }
  it 'empty modes' do
    helpdesk_project.safe_attributes = {
      automatically_issue_closer_enable: true,
      easy_helpdesk_auto_issue_closers_attributes: [options.merge(auto_update_modes: [])]
    }
    expect(helpdesk_project.save).to be_falsey
  end

  it 'wrong modes' do
    helpdesk_project.safe_attributes = {
      automatically_issue_closer_enable: true,
      easy_helpdesk_auto_issue_closers_attributes: [options.merge(auto_update_modes: [:destroy])]
    }
    expect(helpdesk_project.save).to be_falsey
  end

  it 'update' do
    helpdesk_project.safe_attributes = {
      automatically_issue_closer_enable: true,
      easy_helpdesk_auto_issue_closers_attributes: [options.merge(auto_update_modes: [:change])]
    }

    expect(helpdesk_project.save).to be_truthy

    # issue updated_on Time.now
    expect(automat.execute).to eq([true, 0])

    with_time_travel(10.hours) do
      msg = I18n.t(:text_easy_rake_task_helpdesk_issue_closer_updated, updated_count: 3, notified_count: 0)
      expect(automat.execute).to eq([true, msg])
    end

    issues.each(&:reload)
    expect(issues.map(&:assigned_to_id).compact.uniq).to match_array([User.current.id])
    expect(issues.map(&:status).compact.uniq).to match_array([status])
    expect(issues.map(&:easy_closed_by_id).compact.uniq).to match_array([User.current.id])
    expect(issues.map(&:closed_on).compact.uniq).not_to be_empty
  end

  it 'notify' do
    template = FactoryBot.create(:easy_helpdesk_mail_template)
    helpdesk_project.safe_attributes = {
      automatically_issue_closer_enable: true,
      easy_helpdesk_auto_issue_closers_attributes: [options.merge(auto_update_modes: [:notify], easy_helpdesk_mail_template_id: template.id)]
    }

    expect(helpdesk_project.save).to be_truthy

    # issue updated_on Time.now
    expect(automat.execute).to eq([true, 0])

    with_time_travel(10.hours) do
      # easy_email_to blank
      expect{ automat.execute }.to_not change { EasyExternalMailer.deliveries.count }

      # easy_email_to filled
      allow_any_instance_of(Issue).to receive(:easy_email_to).and_return('customer@test.test')
      return_value = nil
      msg = I18n.t(:text_easy_rake_task_helpdesk_issue_closer_updated, updated_count: 0, notified_count: 3)
      expect{ return_value = automat.execute }.to change { EasyExternalMailer.deliveries.count }.by(3)
      expect(return_value).to eq([true, msg])
    end

  end
end
