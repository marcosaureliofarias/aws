require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, logged: :admin do
  render_views

  it 'parent issues' do
    get :index, params: { autocomplete_action: 'parent_issues', format: 'json' }
    expect(response).to be_successful
  end

  it 'visible issues' do
    get :index, params: { autocomplete_action: 'issue_autocomplete', format: 'json' }
    expect(response).to be_successful
  end

  it 'query entities' do
    get :index, params: { autocomplete_action: 'query_entities', format: 'json', autocomplete_options: { entity: 'User' } }
    expect(response).to be_successful
  end

  it 'attendance_report_users' do
    get :index, params: { autocomplete_action: 'attendance_report_users', format: 'json' }
    expect(response).to be_successful
  end

  it 'ckeditor_issues' do
    get :index, params: { autocomplete_action: 'ckeditor_issues', format: 'json', query: 'test' }
    expect(response).to be_successful
  end

  it 'tags' do
    get :index, params: { autocomplete_action: 'tags', format: :json }
    expect(response).to be_successful
  end

  context 'users for query copy', logged: true do
    let(:easy_query) { FactoryGirl.create(:easy_issue_query, visibility: EasyQuery::VISIBILITY_PUBLIC) }
    let(:user2) { FactoryGirl.create(:user) }

    it 'without query' do
      get :index, params: { autocomplete_action: 'users_for_query_copy', format: 'json' }
      expect(response).to have_http_status(404)
    end

    it 'with query' do
      user2
      get :index, params: { autocomplete_action: 'users_for_query_copy', format: 'json', easy_query_id: easy_query.id }
      expect(response).to be_successful
      ids = assigns(:users).map(&:id)
      expect(ids).not_to include(user2.id)
      expect(ids).to include(User.current.id)
    end
  end

  it 'project_entities' do
    get :index, params: { autocomplete_action: 'project_entities', entity_type: 'Project', format: :json }
    expect(response).to be_successful
  end

  it 'managed_users' do
    allow(controller).to receive(:get_active_users).and_return([])
    get :index, params: { autocomplete_action: 'managed_users', format: :json }
    expect(response).to be_successful
  end

  context 'user autocomplete', logged: true do

    around(:each) do |example|
      with_settings(issue_group_assignment: 1) { example.run }
    end

    let(:group) { FactoryGirl.create(:group) }
    let(:user3) { FactoryGirl.create(:user) }
    let(:issue1) { FactoryGirl.create(:issue, assigned_to_id: group.id) }
    let(:issue2) { FactoryGirl.create(:issue, assigned_to_id: user3.id) }

    it 'issue assigned to group' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue1.id }
      expect(response).to be_successful
    end

    it 'issue assigned to user' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue2.id }
      expect(response).to be_successful
    end

    it 'bulk edit with different project' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', project_ids: [issue2.project_id, issue1.project_id] }
      expect(response).to be_successful
    end

    it 'new issue with only project' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', project_id: issue1.project_id }
      expect(response).to be_successful
    end

    context 'limited users' do
      let(:user) { FactoryBot.create(:user) }
      let(:project) { FactoryBot.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0, members: [User.current, user]) }
      let(:issue) { FactoryBot.create(:issue, project: project, assigned_to_id: User.current.id, author_id: User.current.id) }

      after(:each) do
        allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_call_original
      end

      it 'enabled' do
        allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_return(true)
        get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id }
        expect(response).to be_successful
        body = response.body
        expect(body).to include(I18n.t(:label_me))
        expect(body).not_to include(I18n.t(:label_nobody))
      end

      it 'disabled' do
        allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_return(false)
        get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id }
        expect(response).to be_successful
        body = response.body
        expect(body).to include(I18n.t(:label_me))
        expect(body).to include(I18n.t(:label_nobody))
      end
    end

    describe '#grouped_users_in_meeting_calendar', logged: :admin do
      let(:meeting_type) { FactoryBot.create(:easy_user_type, show_in_meeting_calendar: true) }
      let!(:meeting_user) { FactoryBot.create(:user, firstname: 'john', lastname: 'doe', easy_user_type: meeting_type) }
      let!(:group) { FactoryBot.create(:group, lastname: 'group doe', users: [meeting_user]) }

      context 'users' do
        it "without argument" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json' }
          expect(response).to be_successful
          expect(response.body).to include(meeting_user.name)
        end

        it "finds match" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', term: 'doe' }
          expect(response).to be_successful
          expect(response.body).to include(meeting_user.name)
        end

        it "return nothing for no match" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', term: 'woe' }
          expect(response).to be_successful
          expect(response.body).not_to include(meeting_user.name)
        end

        it "doesnt return groups" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json' }
          expect(response).to be_successful
          expect(response.body).not_to include(group.name)
        end

        context 'used user ids' do
          let!(:meeting_user2) { FactoryBot.create(:user, firstname: 'john', lastname: 'zoe', easy_user_type: meeting_type) }

          it 'without filter argument' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', used_user_ids: [meeting_user.id] }
            expect(response).to be_successful
            expect(response.body).not_to include(meeting_user.name)
          end

          it 'witch search matching used user id' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', used_user_ids: [meeting_user.id], term: 'doe' }
            expect(response).to be_successful
            expect(response.body).not_to include(meeting_user.name)
          end

          it 'witch search matching other than used user id' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', used_user_ids: [meeting_user.id], term: 'zoe' }
            expect(response).to be_successful
            expect(response.body).to include(meeting_user2.name)
          end
        end

      end

      context 'groups' do
        it "without argument" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1' }
          expect(response).to be_successful
          expect(response.body).to include(group.name)
        end

        it "finds match" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', term: 'doe' }
          expect(response).to be_successful
          expect(response.body).to include(group.name)
        end

        it "return nothing for no match" do
          get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', term: 'woe' }
          expect(response).to be_successful
          expect(response.body).not_to include(group.name)
        end

        context 'used user ids' do

          let!(:group2) { FactoryBot.create(:group, lastname: 'group foe', users: [meeting_user]) }

          it 'without filter argument' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', used_user_ids: [group.id] }
            expect(response).to be_successful
            expect(response.body).not_to include(group.name)
          end

          it 'witch search matching used user id' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', used_user_ids: [group.id], term: 'doe' }
            expect(response).to be_successful
            expect(response.body).not_to include(group.name)
          end

          it 'witch search matching other than used user id' do
            get :index, params: { autocomplete_action: 'grouped_users_in_meeting_calendar', format: 'json', include_groups: '1', used_user_ids: [group.id], term: 'foe' }
            expect(response).to be_successful
            expect(response.body).to include(group2.name)
          end
        end

      end

    end

    it 'option << me >>' do
      FactoryBot.create(:member, project: issue1.project, user: User.current)
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue1.id }
      users_json = JSON.load(response.body)['users']
      expected_me_option = users_json.detect{|option|
                                                      option['id'] == User.current.id &&
                                                      option['value'] == '<< me >>' &&
                                                      option['category'] == ''
                                            }
      expect(expected_me_option).not_to be_nil
    end
  end

  context 'additional user options' do
    def params(action, options = {})
      { autocomplete_action: action, format: 'json' }.merge(options)
    end

    context '#assignable_principals_issue' do
      let(:issue) { FactoryBot.create(:issue) }
      let(:options) { { issue_id: issue.id, project_id: issue.project.id } }
      let(:additional_user_options) { JSON.load(response.body)['users'].select { |entry| entry['value'].starts_with?('<<') } }

      it 'with options if term blank' do
        get :index, params: params('assignable_principals_issue', options)
        expect(additional_user_options).not_to be_empty
      end

      it 'without options if term sent' do
        get :index, params: params('assignable_principals_issue', options.merge(term: 'te'))
        expect(additional_user_options).to be_empty
      end
    end

    context '#visible_principals' do
      let(:additional_select_options) { assigns[:additional_select_options] }
      before do
        allow(controller).to receive(:visible_principals_values) { Principal.all }
      end

      it 'with options if term blank' do
        get :index, params: params('visible_principals')
        expect(additional_select_options).not_to be_empty
      end

      it 'without options if term sent' do
        get :index, params: params('visible_principals', { term: 'te' })
        expect(additional_select_options).to be_empty
      end
    end
  end

  context '#visible_search_suggester_entities' do
    let!(:closed_project) { FactoryGirl.create(:project, name: 'Test 1', status: Project::STATUS_CLOSED) }
    let!(:active_project) { FactoryGirl.create(:project, name: 'Test 2', status: Project::STATUS_ACTIVE) }

    around do |example|
      with_easy_settings(easy_search_suggester: { 'entity_types' => [] }) { example.run }
    end

    it 'search open project' do
      get :index, params: { autocomplete_action: 'visible_search_suggester_entities', format: 'api', term: 'po:test' }
      projects_suggest_entities = assigns[:suggest_entities].first
      expect(projects_suggest_entities&.first).to be_a_kind_of(EasyExtensions::Suggester::Projects)
      expect(projects_suggest_entities&.last || []).to match_array([active_project])
    end

    it 'search any not archived project' do
      get :index, params: { autocomplete_action: 'visible_search_suggester_entities', format: 'api', term: 'p:test' }
      projects_suggest_entities = assigns[:suggest_entities].first
      expect(projects_suggest_entities&.first).to be_a_kind_of(EasyExtensions::Suggester::Projects)
      expect(projects_suggest_entities&.last || []).to match_array([active_project, closed_project])
    end
  end

  context 'assignable user categories' do

    let(:issue) { FactoryBot.create(:issue) }
    let(:user1) { FactoryBot.create(:user, firstname: 'UserOne', lastname: 'Assignable') }
    let(:user2) { FactoryBot.create(:user, firstname: 'UserTwo', lastname: 'Assignable') }
    let(:group1) { FactoryBot.create(:group, lastname: 'GroupOne Assignable') }
    let(:group2) { FactoryBot.create(:group, lastname: 'GroupTwo Assignable') }
    let(:json_response) { JSON.load(response.body) }
    let(:json_response_categories) { json_response['users'].map { |user| user['category'] }.uniq }
    around(:each) do |example|
      with_settings(issue_group_assignment: 1) { example.run }
    end
    before do
      allow(EasyPrincipalQuery).to receive(:get_assignable_principals) { Principal.where(id: [user1.id, user2.id, group1.id, group2.id]) }
    end

    it 'splits response to categories if assignable user and assignable group present' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id, project_id: issue.project.id }
      expect(json_response_categories).to include('')
      expect(json_response_categories).to include('Users')
      expect(json_response_categories).to include('Groups')
    end

    it 'omits categories if only 1 user' do
      allow(EasyPrincipalQuery).to receive(:get_assignable_principals) { Principal.where(id: [user1.id]) }
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id, project_id: issue.project.id, term: 'UserOne' }
      expect(json_response_categories).to include('')
      expect(json_response_categories.count).to be(1)
    end

    it 'omits categories if only 1 group' do
      allow(EasyPrincipalQuery).to receive(:get_assignable_principals) { Principal.where(id: [group1.id]) }
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id, project_id: issue.project.id, term: 'GroupOne' }
      expect(json_response_categories).to include('')
      expect(json_response_categories.count).to be(1)
    end

    it 'shows category if more than 1 user' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id, project_id: issue.project.id, term: 'User' }
      expect(json_response_categories).to include('Users')
    end

    it 'shows category if more than 1 group' do
      get :index, params: { autocomplete_action: 'assignable_principals_issue', format: 'json', issue_id: issue.id, project_id: issue.project.id, term: 'Group' }
      expect(json_response_categories).to include('Groups')
    end
  end

  context '#allowed_issue_statuses', logged: true do
    include_context 'workflows_support'
    let(:json_response) { JSON.load(response.body) }
    before do
      allow_any_instance_of(Tracker).to receive(:default_status) { issue_status2 }
      issue_status1
      issue_status2
      project
    end

    it 'should include default status for new issue created on project' do
      get :index, params: { autocomplete_action: 'allowed_issue_statuses', project_id: project.id, format: :json }
      expect(json_response).to match_array([{ 'text' => issue_status2.name, 'value' => issue_status2.id }])
    end

    it 'should include all allowed statuses' do
      role = User.current.reload.roles.first
      WorkflowTransition.create!(role_id: role.id, tracker_id: tracker.id, old_status_id: 0, new_status_id: issue_status1.id)
      get :index, params: { autocomplete_action: 'allowed_issue_statuses', project_id: project.id, format: :json }
      expect(json_response).to match_array([{ 'text' => issue_status2.name, 'value' => issue_status2.id }, { 'text' => issue_status1.name, 'value' => issue_status1.id }])
    end
  end

end
