require_relative '../spec_helper'

describe EasyCrmKanbanController, :logged => :admin do

  render_views

  it 'save_settings' do
    post :save_settings, params: { easy_setting: {easy_crm_case_kanban_project_settings: {'0' => {name: 'xx', easy_crm_case_statuses: ['1']}}} }
    expect(assigns(:easy_crm_kanban_settings)).not_to be_blank
    expect(response).to redirect_to(easy_crm_settings_global_path(tab: 'easy_crm_kanban_settings'))
  end
end
