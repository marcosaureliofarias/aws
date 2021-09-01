require_relative '../spec_helper'

RSpec.describe 'Issue new form with watchers autocomplete', logged: :admin, type: :request do

  let(:user) { user = FactoryGirl.create(:user); project.members << Member.new(:project => project, :principal => user, :roles => [role]); user }
  let(:user1) { user = FactoryGirl.create(:user); project.members << Member.new(:project => project, :principal => user, :roles => [role]); user }
  let(:project) { FactoryGirl.create(:project) }
  let(:issue) { FactoryGirl.create(:issue, project: project, watchers: [user]) }
  let(:group) { group = FactoryBot.build(:group); project.members << Member.new(:project => project, :principal => group, :roles => [role]); group }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_issues, :edit_issues]) }

  it 'check correct render partials' do
    post project_issues_new_path(project.id)
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:new)
    expect(response).to render_template(partial: 'watchers/_watchers_avatar_and_checkbox_with_groups')
    expect(response).not_to render_template(partial: 'watchers/_selected_watchers_avatar_and_checkbox')
    expect(response).to render_template(partial: 'easy_watchers_list_autocomplete/_watchers_avatar_and_checkbox_with_groups_original')
  end

  it 'check filtering assignable watchers' do
    post easy_watchers_list_autocomplete_assignable_watchers_path(filter_string: user.name,
                                                    project_id: project.id,
                                                    entity_klass: 'issue',
                                                    selected_watcher_ids: [],
                                                    format: 'js')
    expect(response).to have_http_status(:success)
    expect(response.body).to include user.name
    expect(response.body).not_to include user1.name
  end

  describe 'issue new form' do
    context 'with user params' do
      it 'selected user watchers' do
        post project_issues_new_path(project.id, issue: { watcher_user_ids: user.id })
        expect(response).to have_http_status(:success)
        expect(response.body).to include "user-#{user.id} link-list-item checked form-entity-watcher-container issue"
      end
    end

    context 'with group params' do
      it 'selected group watchers' do
        post project_issues_new_path(project.id, issue: { watcher_group_ids: group.id })
        expect(response).to have_http_status(:success)
        expect(response.body).to include "group-#{group.id} link-list-item checked form-entity-watcher-container issue"
      end
    end
  end

end
