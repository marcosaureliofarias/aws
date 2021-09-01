require_relative '../spec_helper'

module EasyWatchersListAutocomplete
  RSpec.describe EasyWatchersListAutocompleteController, type: :controller, logged: :admin do

    let(:user) { user = FactoryBot.create(:user); project.members << Member.new(:project => project, :principal => user, :roles => [role]); user }
    let(:user1) { user = FactoryBot.create(:user); project.members << Member.new(:project => project, :principal => user, :roles => [role]); user }
    let(:project) { FactoryBot.create(:project) }
    let(:issue) { FactoryBot.create(:issue, project: project) }
    let(:group) { group = FactoryBot.build(:group); project.members << Member.new(:project => project, :principal => group, :roles => [role]); group }
    let(:group1) { group = FactoryBot.build(:group); project.members << Member.new(:project => project, :principal => group, :roles => [role]); group }
    let(:role) { FactoryBot.create(:role, permissions: [:view_issues, :edit_issues]) }

    it 'assignable watchers start filtering' do
      available_groups = issue.available_groups.first(EasyWatchersListAutocomplete.setting(:watchers_groups_limit))
      available_users = issue.addable_watcher_users.first(EasyWatchersListAutocomplete.setting(:watchers_users_limit))

      post :assignable_watchers, params: {filter_string: '', project_id: project.id, entity_klass: 'issue', selected_watcher_ids: [], format: 'js'}
      expect(response).to be_successful
      expect(assigns(:users)).to eq(available_users)
      expect(assigns(:groups)).to eq(available_groups)
    end

    it 'assignable watchers filtering specific user name' do
      post :assignable_watchers, params: {filter_string: user.name, project_id: project.id, entity_klass: 'issue', selected_watcher_ids: [], format: 'js'}

      expect(response).to be_successful
      expect(assigns(:users)).to eq([user])
      expect(assigns(:groups)).to eq([])
    end

    it 'assignable watchers filtering specific group' do
      post :assignable_watchers, params: {filter_string: group.name, project_id: project.id, entity_klass: 'issue', selected_watcher_ids: [], format: 'js'}

      expect(response).to be_successful
      expect(assigns(:users)).to eq([])
      expect(assigns(:groups)).to eq([group])
    end

    it 'assignable watchers filtering unassignbale user' do
      post :assignable_watchers, params: {filter_string: 'unassignbale user', project_id: project.id, entity_klass: 'issue', selected_watcher_ids: [], format: 'js'}

      expect(response).to be_successful
      expect(assigns(:users)).to eq([])
      expect(assigns(:groups)).to eq([])
    end

  end
end