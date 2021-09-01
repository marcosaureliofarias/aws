RSpec.shared_context "sla support" do
  let(:start_status) { FactoryBot.create(:issue_status)}
  let(:stop_status) { FactoryBot.create(:issue_status)}

  def with_sla_stop_start_states_settings(&block)
    sla_statuses = {}
    sla_statuses['easy_helpdesk_sla_stop_states'] = [stop_status.id.to_s]
    sla_statuses['easy_helpdesk_sla_start_states'] = [start_status.id.to_s]
    with_easy_settings(sla_statuses, &block)
  end
end
RSpec.shared_context 'easy_helpdesk_send_quick_external_mail' do
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:easy_helpdesk_mail_template) { FactoryBot.create(:easy_helpdesk_mail_template, issue_status: issue.status) }

  before do
    allow_any_instance_of(Issue).to receive(:maintained_by_easy_helpdesk?) { true }
    allow_any_instance_of(Issue).to receive(:easy_email_to) { 'test@test.com' }
    allow_any_instance_of(Issue).to receive(:maintained_easy_helpdesk_project) { EasyHelpdeskProject.new }
  end
end
RSpec.shared_context 'sla_event_support' do
  let!(:easy_helpdesk_project) { FactoryBot.create(:easy_helpdesk_project, project: easy_sla_event.project) }
  let(:easy_sla_event) { FactoryBot.create(:easy_sla_event) }
  let(:role) { FactoryBot.create(:role, permissions: [:manage_easy_sla_events]) }
  let(:user_allowed_to_manage_sla_event) do
    user = FactoryBot.create(:user)
    FactoryBot.create(:member, project: easy_sla_event.project, user: user, roles: [role])
    user
  end
end

