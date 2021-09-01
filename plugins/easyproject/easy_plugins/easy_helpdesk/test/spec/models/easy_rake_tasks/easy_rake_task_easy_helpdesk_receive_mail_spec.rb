require 'easy_extensions/spec_helper'

describe EasyRakeTaskEasyHelpdeskReceiveMail do

  context 'create_default_options_from_settings' do
    let(:task) { FactoryBot.create(:easy_rake_task_easy_helpdesk_receive_mail, settings: { skip_ignored_emails_headers_check: '1' }) }

    it { expect(task.create_default_options_from_settings({})[:skip_ignored_emails_headers_check]).to eq('1') }

  end
end
