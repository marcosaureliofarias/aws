require 'easy_extensions/spec_helper'

describe EasyExternalEmailsController, logged: :admin do

  HOURS_TO_RESPONSE = 3
  HOURS_TO_SOLVE = 4
  let(:easy_helpdesk_project_sla) { FactoryGirl.create(:easy_helpdesk_project_sla, hours_to_response: HOURS_TO_RESPONSE, hours_to_solve: HOURS_TO_SOLVE) }

  let(:issue_status_normal) { FactoryGirl.create(:issue_status, is_closed: false) }
  let(:issue_status_stop_status) { FactoryGirl.create(:issue_status, is_closed: false) }
  let(:issue_status_closed) { FactoryGirl.create(:issue_status, is_closed: true) }

  let(:issue) { FactoryGirl.create(:issue, project: easy_helpdesk_project_sla.easy_helpdesk_project.project, status: issue_status_normal, priority: easy_helpdesk_project_sla.priority) }

  it 'create easy sla event after send external email and issue status is in sla stop states' do
    with_easy_settings({ easy_helpdesk_sla_stop_states: [issue_status_stop_status.id.to_s] }) do
      issue.status = issue_status_stop_status
      issue.save

      expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(1)
    end
  end

  it 'create easy sla event after send external email and issue status is close' do
    with_easy_settings({ easy_helpdesk_sla_stop_states: [issue_status_stop_status.id.to_s] }) do
      issue.status = issue_status_closed
      issue.save

      expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(1)
    end
  end

  it 'after send external email on issue not create easy sla event because status not in sla stop statuses' do
    with_easy_settings({ easy_helpdesk_sla_stop_states: [issue_status_stop_status.id.to_s] }) do

      expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(0)
    end
  end

  it 'check correct calculation sla event times' do
    User.current.pref.time_zone = 'Hawaii'
    issue.status = issue_status_closed
    issue.created_on = issue.created_on - 1.hour
    issue.save

    expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(1)
    first_sla_event = issue.easy_sla_events.first

    start = issue.created_on.localtime
    expected_reponse_datetime = start + HOURS_TO_RESPONSE.hours
    expect(first_sla_event.sla_response.localtime).to be_within(1.second).of expected_reponse_datetime

    first_sla_event.reload
    issue.reload
    expect(first_sla_event.sla_response.localtime).to eq(issue.easy_response_date_time.localtime)

    expect(first_sla_event.first_response.present?).to be true
    expect((first_sla_event.first_response.hour / 1.hour).round(2)).to eq(1.00)

    expect((first_sla_event.sla_response_fulfilment.hour / 1.hour).round(2)).to eq(2.00)
    expect((first_sla_event.sla_resolve_fulfilment.hour / 1.hour).round(2)).to eq(3.00)

    expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(1)
    expect(issue.easy_sla_events.count).to eq(2)
    second_sla_event = issue.easy_sla_events.second
    expect(second_sla_event.first_response.present?).to be false
  end

  it '# easy sla event with setting ignorate suspend statusess' do
    with_easy_settings({ easy_helpdesk_sla_stop_states: [issue_status_stop_status.id.to_s], easy_helpdesk_ignorate_suspend_statuses: true }) do

      expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(1)
    end
  end

  it '# easy sla event without setting ignorate suspend statusess' do
    with_easy_settings({ easy_helpdesk_sla_stop_states: [issue_status_stop_status.id.to_s], easy_helpdesk_ignorate_suspend_statuses: false }) do

      expect { post :send_external_email, params: {project_id: issue.project.id, entity_type: 'Issue', entity_id: issue.id, mail_sender: 'lala@glob.cz', mail_recepient: 'tralala@globik.cz', mail_subject: 'test', mail_body_html: 'funguj', mail_body_plain: 'projistotu'} }.to change(EasySlaEvent, :count).by(0)
    end
  end

  describe '#set_easy_extensions_easy_helpdesk_mail_template_issue' do

    subject { described_class.new }

    let(:journal) { FactoryBot.build(:journal, notes: 'Journal notes', journalized: issue) }
    let(:default_template) { EasyHelpdeskMailTemplate.new(is_default: true, body_html: '<p> Default template text </p>', subject: 'Mail subject') }
    let(:easy_mail_template) { EasyExtensions::EasyMailTemplateIssue.new }

    around(:each) do |example|
      with_settings('text_formatting' => 'HTML') { example.run }
    end

    it 'with default mail template' do
      allow_any_instance_of(described_class).to receive(:params).and_return({})
      default_template.save(validate: false)
      subject.send(:set_easy_extensions_easy_helpdesk_mail_template_issue, easy_mail_template, journal.issue, journal)
      expect(easy_mail_template.mail_body_html).to eq('<p> Default template text </p>')
    end

    it 'without default mail template' do
      allow_any_instance_of(described_class).to receive(:params).and_return({})
      subject.send(:set_easy_extensions_easy_helpdesk_mail_template_issue, easy_mail_template, journal.issue, journal)
      expect(easy_mail_template.mail_body_html).to eq('Journal notes<br /><blockquote></blockquote>')
    end
  end

end
