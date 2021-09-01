require 'easy_extensions/spec_helper'

describe EasyIssueTimersController, logged: :admin do
  let(:project) { FactoryBot.create(:project) }

  it 'update project settings' do
    post :update_settings, params: { project_id: project.id, active: '1' }
    expect(response).to have_http_status(302)
    expect(EasySetting.value(:easy_issue_timer_settings, project)[:active]).to be true
  end

end
