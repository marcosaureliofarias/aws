require 'easy_extensions/spec_helper'

describe AdminController, logged: :admin do

  let!(:archived) { FactoryGirl.create(:project, status: Project::STATUS_ARCHIVED) }
  let!(:parent) { FactoryGirl.create(:project) }
  let!(:archived_child) { FactoryGirl.create(:project, parent: parent, status: Project::STATUS_ARCHIVED) }
  let!(:closed_child) { FactoryGirl.create(:project, parent: parent, status: Project::STATUS_CLOSED) }
  let!(:active_child) { FactoryGirl.create(:project, parent: parent) }

  context '#projects' do

    it 'should select active project by default' do
      get :projects
      expect(assigns(:projects).collect(&:id)).to match_array([parent.id])
    end

    it 'return all projects if status is all' do
      all_statuses = [Project::STATUS_ACTIVE, Project::STATUS_ARCHIVED, Project::STATUS_CLOSED, Project::STATUS_PLANNED]
      get :projects, params: { f: { status: '=' + all_statuses.join('|') } }
      projects = assigns(:projects)
      expect(projects.collect(&:id)).to match_array([parent.id, archived.id])
      expect(projects.select { |p| p.has_visible_children? }.collect(&:id)).to match_array([parent.id])
    end

    it 'return archived child project' do
      get :projects, params: { f: { status: '=' + Project::STATUS_ARCHIVED.to_s } }
      projects = assigns(:projects)
      expect(projects.collect(&:id)).to match_array([parent.id, archived.id])
      expect(projects.select { |p| p.has_visible_children? }.collect(&:id)).to match_array([parent.id])
      expect(assigns(:entity_count)).to eq(2)
    end

    it 'return active subprojects with id' do
      get :projects, :params => { root_id: parent.id }, :xhr => true
      expect(assigns(:projects).collect(&:id)).to match_array([active_child.id])
    end

    context 'EXPORTS' do
      let(:easy_query_params) { { set_filter: '0', f: { status: '=' + Project::STATUS_ARCHIVED.to_s } } }
      render_views

      it 'exports to pdf' do
        get :projects, params: easy_query_params, format: :pdf
        expect(response).to be_successful
        projects = assigns[:entities].dig(nil, :entities) || []
        expect(projects.map(&:id)).to match_array([archived.id, archived_child.id])
        expect(response.content_type).to eq('application/pdf')
      end

      it 'exports to xlsx' do
        get :projects, params: easy_query_params, format: :xlsx
        expect(response).to be_successful
        projects = assigns[:entities].dig(nil, :entities) || []
        expect(projects.map(&:id)).to match_array([archived.id, archived_child.id])
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      it 'exports to csv' do
        get :projects, params: easy_query_params, format: :csv
        expect(response).to be_successful
        projects = (assigns[:entities].dig(nil, :entities) || []).map(&:id)
        expect(projects).to match_array([archived.id, archived_child.id])
        expect(response.content_type).to include('text/csv')
      end
    end

  end

  context 'info' do
    render_views

    it 'show environment' do
      get :info
      expect(response).to be_successful
    end

    it 'regular user', logged: true do
      get :info
      expect(response).to be_forbidden
    end
  end

  describe '#index', logged: true do
    context 'with easy lesser admin permissions' do
      let(:user) { FactoryBot.create(:user, easy_lesser_admin: true, admin: false) }
      it 'should access allowed' do
        allow(User).to receive(:current).and_return user
        get :index
        expect(response).to be_successful
      end
    end
  end

end
