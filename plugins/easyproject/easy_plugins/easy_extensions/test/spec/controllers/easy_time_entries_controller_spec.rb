require 'easy_extensions/spec_helper'

describe EasyTimeEntriesController, type: :controller do
  include_context 'logged as admin'
  include_context 'easy time entries'

  describe 'timelog edit' do
    render_views

    it '#edit' do
      get :edit, params: { id: time_entry.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template('bulk_time_entries/index')
      expect(assigns(:activity_collection)).not_to be_blank
    end

    it '#update' do
      put :update, params: { id: time_entry.id, time_entry: { hours: '15' } }
      expect(time_entry.reload.hours).to eq(15)
    end
  end

  it '#destroy' do
    time_entry
    expect {
      delete :destroy, params: { id: time_entry.id, format: 'json' }
    }.to change(TimeEntry, :count).by(-1)
  end

  context 'validate limits' do

    include_context 'logged as with permissions', :log_time, :edit_time_entries, :add_timeentries_for_other_users

    let(:project) { FactoryBot.create(:project, members: [User.current], add_modules: ['time_tracking']) }
    let(:time_entry) { FactoryBot.create(:time_entry, project: project, issue: nil) }

    it '#destroy locked entry' do
      time_entry
      allow_any_instance_of(TimeEntry).to receive(:get_limit_day).and_return(0)
      expect {
        delete :destroy, params: { id: time_entry.id, format: 'json' }
      }.to change(TimeEntry, :count).by(0)
    end

    it '#destroy unlocked entry' do
      time_entry
      expect {
        delete :destroy, params: { id: time_entry.id, format: 'json' }
      }.to change(TimeEntry, :count).by(-1)
    end
  end

  it 'without lock setting' do
    post :resolve_easy_lock, params: { id: time_entry.id, locked: true }
    expect(time_entry.easy_locked?).to be(false)
  end

  describe 'bulk_edit' do

    it '#bulk_edit' do
      get :bulk_edit, params: { ids: time_entries.map(&:id) }
      expect(response).to have_http_status(:success)
      expect(response).to render_template('timelog/bulk_edit')
    end

    it 'bulk_edit invalid id' do
      get :bulk_edit, params: { ids: time_entries.map(&:id), time_entry: { issue_id: Issue.last.id + 1 } }
      expect(response).to have_http_status(:success)
    end

    it '#change_projects_for_bulk_edit' do
      get :change_projects_for_bulk_edit, params: { ids: time_entries.map(&:id), format: 'json' }
      expect(response).to have_http_status(:success)
      expect(response).to render_template('timelog/change_projects_for_bulk_edit')
    end

    it '#change_issues_for_bulk_edit' do
      post :change_issues_for_bulk_edit, params: { ids: time_entries.map(&:id), format: 'json' }
      expect(response).to have_http_status(:success)
      expect(response).to render_template('timelog/change_issues_for_bulk_edit')
    end
  end

  describe 'bulk_update' do
    render_views

    it 'update with locked time entry' do
      with_easy_settings(time_entries_locking_enabled: true) do
        ids = [time_entry.id, time_entry_locked.id]
        post :bulk_update, params: { ids: ids, time_entry: { project_id: project.id, issue_id: '' } }
        expect(response).to have_http_status(:success)
      end
    end
  end

  context 'EXPORTS' do
    render_views

    it 'exports to xlsx' do
      get :index, params: { format: 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    context '#report' do
      let!(:time_entry) { FactoryBot.create(:time_entry) }

      it 'export to xlsx' do
        get :report, params: { format: 'xlsx', set_filter: '1', criteria: ['project', 'activity'], columns: ['month'] }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      it 'export to csv' do
        get :report, params: { format: 'csv', set_filter: '1', criteria: ['project', 'activity'], columns: ['month'] }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/csv')
      end
    end
  end

  context '#index' do
    render_views

    include_context 'logged as with permissions', :log_time
    
    it 'redmine api filter' do
      get :index, params: { format: 'json', set_filter: '1', spent_on: '=2017-10-26' }
      expect(response).to have_http_status(:success)
    end

    it 'additional statement' do
      time_entry
      allow(TimeEntry).to receive(:visible_condition).and_return("")
      with_settings(display_subprojects_issues: '1') do
        get :index, params: { format: 'json', project_id: time_entry.project_id, set_filter: '1', spent_on: 'all' }
        expect(response).to have_http_status(:success)
        expect(assigns(:entities)).to include(time_entry)
      end
    end
  end

  it 'task totals' do
    get :index, params: { format: 'json', set_filter: '1', issue_id: time_entry.issue_id, period: 'all', with_descendants: 'true' }
    expect(response).to have_http_status(:success)
    expect(assigns(:entities)).to include(time_entry)
  end

  context '#new' do
    let(:issue) { FactoryBot.create(:issue) }
    let(:project) { FactoryBot.create(:project) }
    let(:role) { FactoryBot.create(:role, permissions: [:log_time]) }
    let(:member) { FactoryBot.create(:member, project: project, user: User.current, roles: [role]) }

    it 'with issue_id' do
      allow_any_instance_of(EasyTimeEntriesController).to receive(:get_last_project).and_return(project)
      get :new, params: { issue_id: issue.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:time_entry).project).to eq(issue.project)
    end

    it 'activity by roles' do
      member
      with_easy_settings(enable_activity_roles: true) {
        get :new, params: { user_role_id_time_entry: '-1', user_id: User.current.id, project_id: project.id }
        expect(assigns(:user).selected_role_id).to eq('xAll')
      }
    end

  end

  context '#load_users' do
    let!(:user2) { FactoryBot.create(:user) }
    let!(:project) { FactoryBot.create(:project, number_of_issues: 0, add_modules: ['time_tracking']) }
    let!(:role) { FactoryBot.create(:role, permissions: [:log_time]) }
    let!(:member) { FactoryBot.create(:member, project: project, user: user2, roles: [role]) }

    render_views

    context 'other users on project' do
      include_context 'logged as with permissions', :log_time, :add_timeentries_for_other_users_on_project

      it do
        allow(User).to receive(:visible).and_return(User.all)
        get :load_users, params: { format: 'json', project_id: project.id }
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to include({"value"=>user2.name, "id"=>user2.id})
      end
    end

    context 'log time' do
      include_context 'logged as with permissions', :log_time

      it do
        allow(User).to receive(:visible).and_return(User.all)
        get :load_users, params: { format: 'json', project_id: project.id }
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).not_to include({"value"=>user2.name, "id"=>user2.id})
      end
    end
  end

  context '#load_assigned_issues' do
    let!(:project) { FactoryBot.create(:project, add_modules: ['time_tracking'], number_of_issues: 1) }
    let!(:sub_project) { FactoryBot.create(:project, add_modules: ['time_tracking'], number_of_issues: 1, parent: project) }
    let!(:user) { FactoryBot.create(:admin_user) }

    around(:each) do |ex|
      with_settings(display_subprojects_issues: '1') do
        ex.run
      end
    end

    it 'with subprojects' do
      get :load_assigned_issues, params: { format: 'json', user_id: user.id, project_id: project.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it 'without subprojects' do
      get :load_assigned_issues, params: { format: 'json', user_id: user.id, without_subprojects: '1', project_id: project.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe '#find_optional_project' do
    let(:project) { double(Project, module_enabled?: true) }
    let(:issue) { double(Issue, project: nil) }
    let(:params) {
      ActionController::Parameters.new({
                                           project_changed: '1',
                                           project_id:      '999',
                                           issue_id:        '111',
                                       })
    }

    context 'changing project' do
      it 'returns selected project' do
        controller.params = params
        allow(Project).to receive(:find).with('999').and_return(project)
        allow(Issue).to receive(:find_by).with(id: '111').and_return(issue)

        expect(controller.send(:find_optional_project)).to eq(project)
      end
    end

  end

  context 'query' do
    let!(:time_entry) { FactoryBot.create(:time_entry) }

    it 'load a blank group' do
      get :index, params: { set_filter: '1', group_to_load: [''], group_by: ['parent_project'] }, xhr: true
      expect(response).to be_successful
      expect(assigns[:entities]).to eq([time_entry])
    end
  end
end
