require 'easy_extensions/spec_helper'

describe EasyHelpdeskProject, logged: :admin do
  let(:easy_helpdesk_project_matching) {
    FactoryGirl.create(:easy_helpdesk_project_matching)
  }
  let(:active_easy_helpdesk_project) {
    easy_helpdesk_project_matching.easy_helpdesk_project
  }
  let(:archived_easy_helpdesk_project) {
    easy_helpdesk_project = easy_helpdesk_project_matching.easy_helpdesk_project
    easy_helpdesk_project.project.archive
    easy_helpdesk_project
  }

  let(:easy_helpdesk_received_email) {
    easy_helpdesk_email = double('Email')
    allow(easy_helpdesk_email).to receive_messages(:from => 'koala@' + easy_helpdesk_project_matching.domain_name, :to => 'wombat@dkdkkd.kd')
    easy_helpdesk_email
  }

  it 'should not find_by_email archived project' do
    archived_easy_helpdesk_project
    expect(EasyHelpdeskProject.find_by_email(easy_helpdesk_received_email)).not_to be_present
  end

  it 'should find_by_email active project' do
    active_easy_helpdesk_project
    expect(EasyHelpdeskProject.find_by_email(easy_helpdesk_received_email)).to be_present
  end

end
