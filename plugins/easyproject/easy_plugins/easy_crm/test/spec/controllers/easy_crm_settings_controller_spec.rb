require_relative '../spec_helper'

describe EasyCrmSettingsController, :logged => :admin do
  let(:project) { FactoryGirl.create(:project, :with_categories, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  render_views

  it 'show project index with issue categories' do
    get :project_index, :params => {:id => project.id}
    assert_response :success
  end

  it 'tabs' do
    ['easy_crm_case_statuses', 'easy_user_targets', 'easy_crm_kanban_settings', 'others'].each do |tab|
      get :index, :params => {:tab => tab}
      raise "response: #{response.status} on tab #{tab}" if response.status != 200
    end
  end
end
