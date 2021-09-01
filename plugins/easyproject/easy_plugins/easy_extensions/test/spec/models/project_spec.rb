require 'easy_extensions/spec_helper'

RSpec.shared_examples 'a new project' do |copy_type|
  context "created through #{copy_type}" do
    before do
      @new_project = @project.create_project_template(copying_action: copy_type)
    end

    it 'with correct saved queries' do
      expect(@new_project.easy_queries.size).to eq(@project.easy_queries.size)

      @new_project.easy_queries.each do |query|
        expect(
            query.entities.map { |issue| issue.subject }
        ).to match_array(@origin_issues[query.name])
      end
    end

    it 'with correct page modules' do
      page    = EasyPage.find_by(page_name: 'project-overview')
      modules = EasyPageZoneModule.where(easy_pages_id: page.id, entity_id: @new_project.id)
      modules.each do |zone_module|
        next unless zone_module.module_definition.query_module?

        settings = zone_module.settings #.with_indifferent_access

        name          = settings.delete(:query_name)
        query         = settings.delete(:type).constantize.new
        query.project = @new_project
        query.from_params(settings)

        expect(
            query.entities.map { |issue| issue.subject }
        ).to match_array(@origin_issues[name])
      end

    end
  end
end

RSpec.describe Project, :type => :model do

  # Keep all variables as instance in before block
  # RSpec 2 is problematic when you use let-before-shared_examples
  # + this behavior is deprecated in RSpec3
  context 'copying' do

    # Create project and assign versions and categories
    before do
      @project = FactoryGirl.create(:project, :with_categories, :with_milestones, number_of_issues: 10, number_of_versions: 3, number_of_issue_categories: 3)

      @project.issues[0].category = @project.issue_categories[0]
      @project.issues[1].category = @project.issue_categories[1]
      @project.issues[2].category = @project.issue_categories[2]

      @project.issues[3].fixed_version = @project.versions[0]
      @project.issues[4].fixed_version = @project.versions[1]
      @project.issues[5].fixed_version = @project.versions[2]

      @project.issues[6].category      = @project.issue_categories[0]
      @project.issues[6].fixed_version = @project.versions[0]

      @project.issues[7].category      = @project.issue_categories[1]
      @project.issues[7].fixed_version = @project.versions[2]

      @project.issues.each(&:save)
      @project
    end

    # Admin user for permission for all query filters
    before do
      @user = FactoryGirl.create(:user, :admin)
      logged_user(@user)
    end

    # Public project queries
    before do
      @queries = []

      query      = EasyIssueQuery.new
      query.name = 'project_query_1'
      query.add_filter('fixed_version_id', '=', [@project.versions[0].id.to_s])
      @queries << query

      query      = EasyIssueQuery.new
      query.name = 'project_query_2'
      query.add_filter('category_id', '=', [@project.issue_categories[0].id.to_s])
      @queries << query

      query      = EasyIssueQuery.new
      query.name = 'project_query_3'
      query.add_filter('category_id', '=', [@project.issue_categories[0].id.to_s])
      query.add_filter('fixed_version_id', '=', [@project.versions[0].id.to_s])
      @queries << query

      @queries.each do |query|
        query.visibility = EasyQuery::VISIBILITY_PUBLIC
        query.project    = @project
        query.save
      end
    end

    # Remember origin issue subjects
    before do
      @origin_issues = {}
      @project.easy_queries.each do |query|
        @origin_issues[query.name] = query.entities.map { |issue| issue.subject }
      end
      @origin_issues
    end

    # Create page modules, before(:all) is not supported in Rspec 3
    before do
      page = EasyPage.find_by(page_name: 'project-overview')
      zone = page.zones.first

      page_module      = EasyPageModule.find_by_type('EpmIssueQuery')
      available_module = page.modules.where(easy_page_modules_id: page_module.id).first

      @queries.each do |query|
        settings              = query.to_params.with_indifferent_access
        settings[:query_name] = query.name

        page_zone_module = EasyPageZoneModule.new(easy_pages_id: page.id, easy_page_available_zones_id: zone.id, easy_page_available_modules_id: available_module.id, entity_id: @project.id, tab: 1, settings: settings)
        page_zone_module.save!
      end
    end


    it_behaves_like 'a new project', :creating_template
    it_behaves_like 'a new project', :creating_project
    it_behaves_like 'a new project', :copying_project
  end

  describe '#copy' do
    let(:user) { FactoryBot.create(:user) }
    let(:user_in_group) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group, users: [user_in_group]) }
    let(:role) { FactoryBot.create(:role) }
    let(:project_with_group_member) { FactoryBot.create(:project, members: [user]) }
    let(:new_project) { FactoryBot.create(:project) }

    it 'copies members' do
      project_with_group_member.members << Member.new(principal: group, roles: [role])
      project_with_group_member.save

      new_project.copy(project_with_group_member, {})

      expect(new_project.reload.members.pluck(:user_id)).to contain_exactly(user.id, user_in_group.id)
    end
  end

  context 'add default member' do
    let(:user_type_role) { FactoryBot.create(:role) }
    let(:new_project) { FactoryBot.create(:project, members: []) }

    around do |example|
      with_easy_settings(use_default_user_type_role_for_new_project: true) do
        example.run
      end
    end

    it 'user type role present' do
      allow(User.current).to receive(:easy_user_type).and_return(double(default_role: user_type_role))
      member = new_project.add_default_member(User.current)
      expect(member.roles).to match_array([user_type_role])
    end

    it 'user type role blank' do
      allow(User.current).to receive(:easy_user_type).and_return(double(default_role: nil))
      member = new_project.add_default_member(User.current)
      expect(member.roles).not_to match_array(user_type_role)
    end

    it 'user type role blank, use global' do
      allow(User.current).to receive(:easy_user_type).and_return(double(default_role: nil))
      with_settings(new_project_user_role_id: user_type_role.id.to_s) do
        member = new_project.add_default_member(User.current)
        expect(member.roles).to match_array([user_type_role])
      end
    end
  end

  context 'new project from template' do
    let(:parent_project) { FactoryBot.create(:project) }
    let(:invalid_query) { FactoryBot.build(:easy_issue_query,
                                            :project => parent_project,
                                            :filters => { 'tracker_id' => { :values => [(Tracker.last.id + 1).to_s], :operator => '=' } })
    }

    context 'admin', :logged => :admin do
      it 'should create' do
        parent_project.reload
        expect { parent_project.project_from_template(nil, :name => parent_project.name) }.to change(Project, :count).by(1)
      end

      it 'should create with invalid query' do
        allow(invalid_query).to receive(:valid?).and_return(false)

        invalid_query.save(:validate => false)
        expect(invalid_query.valid?).to be false
        parent_project.reload
        expect { parent_project.project_from_template(nil, :name => parent_project.name) }.to change(Project, :count).by(1)
      end
    end

    context 'regular user', :logged => true do
      let!(:parent_project_with_member) { FactoryBot.create(:project, :members => [User.current]) }
      let(:role) { FactoryBot.create(:role) }

      before(:each) do
        role = Role.non_member
        role.add_permission!(:add_project)
        role.reload
        parent_project_with_member.reload
        User.current.reload
      end

      it 'member' do
        with_settings(:new_project_user_role_id => User.current.roles.last.id.to_s) do
          expect { parent_project_with_member.project_from_template(nil, :name => parent_project_with_member.name) }.to change(Project, :count).by(1)
          expect(User.current.member_of?(Project.last)).to be true
        end
      end

      it 'non member' do
        with_settings(:new_project_user_role_id => role.id.to_s) do
          expect { parent_project_with_member.project_from_template(nil, :name => parent_project_with_member.name) }.to change(Project, :count).by(1)
          expect(User.current.member_of?(Project.last)).to be true
        end
      end

      context 'with custom fields' do
        let(:group) { FactoryBot.create(:group, users: [User.current]) }
        let(:role) { FactoryBot.create(:role) }
        let(:project_with_group_member) { FactoryBot.create(:project) }
        let(:user_custom_field) { FactoryBot.create(:project_custom_field, field_format: 'user', is_for_all: true, is_required: true) }
        let(:string_custom_field) { FactoryBot.create(:project_custom_field, field_format: 'string', is_for_all: true, is_required: true) }

        it 'uses correct user scope' do
          project_with_group_member.members << Member.new(principal: group, roles: [role])
          project_with_group_member.save

          new_project_attrs = {
              name:                     project_with_group_member.name,
              custom_field_values:      {
                  user_custom_field.id.to_s   => User.current.id.to_s,
                  string_custom_field.id.to_s => 'test'
              },
              project_custom_field_ids: [user_custom_field.id.to_s, string_custom_field.id.to_s]
          }
          new_project       = project_with_group_member.project_from_template(nil, new_project_attrs, copying_action: :creating_template)

          expect(new_project).to be_persisted # fails if it's invalid before the first save
          expect(new_project.custom_field_value(user_custom_field)).to eq(User.current.id.to_s)
        end
      end
    end

    context 'default role settings for project author', logged: true do
      let(:user_type_role) { FactoryBot.create(:role) }

      before do
        role = Role.non_member
        role.add_permission!(:add_project)
        parent_project.reload
      end

      around do |example|
        with_easy_settings(use_default_user_type_role_for_new_project: true) do
          example.run
        end
      end

      it 'user type role present' do
        allow(User.current).to receive(:easy_user_type).and_return(double(default_role: user_type_role))
        new_project = parent_project.project_from_template(nil, name: parent_project.name)
        member      = new_project.members.find_by(user_id: User.current.id)
        expect(member.roles).to match_array([user_type_role])
      end

      it 'user type role blank' do
        new_project = parent_project.project_from_template(nil, name: parent_project.name)
        member      = new_project.members.find_by(user_id: User.current.id)
        expect(member).to be_nil
      end

      it 'user type role blank, use global' do
        with_settings(new_project_user_role_id: user_type_role.id.to_s) do
          new_project = parent_project.project_from_template(nil, name: parent_project.name)
          member      = new_project.members.find_by(user_id: User.current.id)
          expect(member.roles).to match_array([user_type_role])
        end
      end
    end

    context 'with activities', :logged => :admin do
      let(:child_project) { FactoryBot.create(:project) }
      let(:activity) { FactoryBot.create(:time_entry_activity, projects: [parent_project]) }

      it 'from parent' do
        parent_project.project_time_entry_activities = []
        activity
        p = child_project.project_from_template(parent_project.id, :name => child_project.name, :inherit_time_entry_activities => true)
        p.copy_time_entry_activities_from_parent
        expect(p.project_time_entry_activities.first.id).to eq(activity.id)
      end
    end
  end

  it 'close project' do
    p          = FactoryBot.create(:project)
    updated_on = p.updated_on
    with_time_travel(1.day) do
      p.close
      p.reload
      expect(p.updated_on).not_to eq(updated_on)
    end
  end

  context 'visible scope', logged: true do
    let(:role) { FactoryBot.create(:role, users_visibility: 'members_of_visible_projects') }
    let(:group_non_member) { FactoryBot.create(:member, project: project, principal: Group.non_member, roles: [role]) }
    let(:member) { FactoryBot.create(:member, project: project, user: User.current, roles: [role]) }

    context 'issues' do
      let(:project) { FactoryBot.create(:project, number_of_issues: 1) }

      it 'non member' do
        Role.non_member.remove_permission!(:view_issues)
        group_non_member

        issues = Issue.visible.to_a
        expect(issues.map(&:project_id).uniq).to match_array([project.id])
        expect(issues.map(&:id)).to match_array(Issue.all.select { |issue| issue.visible? }.map(&:id))
      end
    end

    context 'memberships' do
      let(:project) { FactoryBot.create(:project, number_of_issues: 0) }

      before(:each) do
        Role.non_member.update_column(:users_visibility, 'members_of_visible_projects')
        member; group_non_member
      end

      it 'project members' do
        expect(project.memberships.active.visible.to_a.map(&:id)).to match_array([member.id, group_non_member.id])
      end

      it 'call project_ids' do
        allow_any_instance_of(User).to receive(:project_ids).and_return([project.id])
        begin
          project.memberships.active.visible.to_a
          expect(User.current).to have_received(:project_ids).at_least(:once)
        ensure
          allow_any_instance_of(User).to receive(:project_ids).and_call_original
        end
      end
    end
  end

  context 'available trackers', :logged => true do
    let(:project) { FactoryBot.create(:project, :members => [User.current]) }
    it 'return trackers' do
      role = Role.non_member
      role.add_permission!(:add_issues)
      role.reload
      expect(project.available_trackers.count).to eq(2)
    end
  end

  context 'validate identifier', logged: :admin do
    let(:project) { FactoryBot.build(:project) }

    it 'valid' do
      with_easy_settings(project_display_identifiers: true) do
        project.identifier = 'random'
        expect(project.valid?).to eq(true)
      end
    end

    it 'invalid' do
      with_easy_settings(project_display_identifiers: true) do
        project.identifier = 'BF-123'
        expect(project.valid?).to eq(false)
      end
    end
  end

  context 'issue sums' do
    let!(:project1) { FactoryBot.create(:project, number_of_issues: 0, number_of_subprojects: 0, enabled_module_names: ['issue_tracking', 'time_tracking']) }
    let!(:project2) { FactoryBot.create(:project, number_of_issues: 0, number_of_subprojects: 0, parent_id: project1.id, enabled_module_names: ['issue_tracking', 'time_tracking']) }
    let!(:issue1) { FactoryBot.create(:issue, subject: 'issue1', project_id: project1.id, estimated_hours: 10, done_ratio: 10) }
    let!(:issue2) { FactoryBot.create(:issue, subject: 'issue2', project_id: project2.id, estimated_hours: 100, done_ratio: 100) }
    let!(:activity) { FactoryBot.create(:time_entry_activity, projects: [project1, project2]) }
    let!(:time_entry1) { FactoryBot.create(:time_entry, issue_id: issue1.id, activity_id: activity.id, project_id: project1.id, hours: 5) }
    let!(:time_entry2) { FactoryBot.create(:time_entry, issue_id: issue2.id, activity_id: activity.id, project_id: project2.id, hours: 10) }

    before(:each) { project1.reload; project2.reload }

    it 'weighted test division by zero' do
      Issue.update_all(estimated_hours: 0)
      expect(project1.calculate_done_weighted_with_estimated_time).to eq(100)
    end

    ['0', '1'].each do |display_subprojects_issues|
      it "computes sum of issues estimated hours#{(display_subprojects_issues == '1') ? ' with display_subprojects_issues setting' : ''}" do
        with_settings(display_subprojects_issues: display_subprojects_issues) do
          [true, false].each do |only_self|
            sum = project1.sum_of_issues_estimated_hours(only_self)
            expect(sum).to be_kind_of(Numeric)
          end
        end
      end

      ['weighted', 'time_spending', ''].each do |formula|
        it "computes completed percent #{formula.blank? ? '' : "with formula #{formula}"}#{(display_subprojects_issues == '1') ? ' and display_subprojects_issues setting' : ''}" do
          with_settings(display_subprojects_issues: display_subprojects_issues) do
            with_easy_settings(project_completion_formula: formula) do
              [true, false].each do |include_subprojects|
                sum = project1.completed_percent(include_subprojects: include_subprojects)
                expect(sum).to be_kind_of(Numeric)
                is_with_sub_projects = include_subprojects && display_subprojects_issues == '1'
                case formula
                when 'weighted' # (SUM(done_ratio / 100 * estimated_hours) / SUM(estimated_hours) * 100)
                  expect(sum.round).to eq(is_with_sub_projects ? 92 : 10)
                when 'time_spending' # (SUM of time entries' hours / SUM of estimated hours) * 100
                  expect(sum.round).to eq(is_with_sub_projects ? 14 : 50)
                when '' # (SUM of done ratio / COUNT issues)
                  expect(sum.round).to eq(is_with_sub_projects ? 55 : 10)
                end
              end
            end
          end
        end
      end
    end
  end

  context 'indicator value' do
    let(:project) { FactoryBot.create(:project, :easy_due_date => Date.today + 1.day) }
    let(:subproject) { FactoryBot.create(:project, :status => 5, :parent_id => project.id, :easy_due_date => Date.today - 1.day) }

    it 'disregards closed subprojects' do
      with_settings(:display_subprojects_issues => true) do
        expect(project.easy_indicator).to eq(20)
      end
    end
  end

  context 'project activity roles', :logged => :admin do
    let!(:project_activity_role) { FactoryBot.create(:project_activity_role) }
    let(:project) { project_activity_role.project }
    let(:role) { project_activity_role.role }
    let(:role_activity) { project_activity_role.role_activity }

    it 'deletes dependencies after project destroy' do
      expect { project.destroy }.to change(ProjectActivityRole, :count).by(-1)
    end

    it 'deletes dependencies after role destroy' do
      expect { role.destroy }.to change(ProjectActivityRole, :count).by(-1)
    end

    it 'deletes dependencies after activity destroy' do
      expect { role_activity.destroy }.to change(ProjectActivityRole, :count).by(-1)
    end
  end

  context 'when created new or updated' do
    let(:project) { FactoryBot.build(:project, :easy_start_date => Date.today, :easy_due_date => Date.today - 3.days) }

    it 'due date cannot be before start date' do
      with_easy_settings(:project_calculate_start_date => false, :project_calculate_due_date => false) do
        expect(project.valid?).to be false
        expect(project.errors[:easy_due_date]).to include(I18n.t(:due_date_after_start, :scope => [:activerecord, :errors, :messages]))
      end
    end
  end

  context 'allowed parents', :logged => true do
    let!(:project) { FactoryBot.create(:project, :members => [User.current]) }
    let!(:project2) { FactoryBot.create(:project, :members => [User.current]) }
    let!(:template) { FactoryBot.create(:project, :easy_is_easy_template => true, :members => [User.current]) }
    let!(:template2) { FactoryBot.create(:project, :easy_is_easy_template => true, :members => [User.current]) }

    it 'projects' do
      role = Role.non_member
      role.add_permission!(:create_subproject_from_template)
      role.reload; User.current.reload

      template.reload.is_from_template = true
      parents                   = template.allowed_parents(nil, :force => :projects)
      expect(parents).to include(project)
      expect(parents).to include(project2)
      expect(parents).not_to include(template)
      expect(parents).not_to include(template2)
    end

    it 'templates' do
      role = Role.non_member
      role.add_permission!(:add_subprojects)
      role.reload; User.current.reload

      parents = template.reload.allowed_parents(nil, :force => :templates)
      expect(parents).not_to include(project)
      expect(parents).not_to include(project2)
      expect(parents).not_to include(template)
      expect(parents).to include(template2)
    end
  end

  context 'copying contents', logged: :admin do
    let(:project) { FactoryBot.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking']) }
    let(:new_project) { FactoryBot.build(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking']) }
    let(:default_status) { FactoryBot.create(:issue_status) }
    let(:status) { FactoryBot.create(:issue_status) }
    let(:issue_with_watchers) { FactoryBot.create(:issue, subject: 'issue', status: status, project_id: project.id, watchers: [User.current]) }
    let(:project_with_tags) { FactoryBot.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], tag_list: ['hello1', 'hello2']) }
    let(:issue_with_tags) { FactoryBot.create(:issue, subject: 'issue', status: status, project_id: project_with_tags.id, tag_list: ['hello']) }
    let(:group) { FactoryGirl.create(:group) }
    let(:version) { FactoryBot.create(:version, project: project) }
    let(:version_custom_field) { FactoryBot.create(:version_custom_field) }
    let(:issue_with_group_assignee) { FactoryBot.create(:issue, subject: 'issue', status: status, project_id: project.id, assigned_to_id: group.id) }
    let(:project_time_entries) { FactoryBot.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking', 'time_entries', 'time_tracking']) }
    let(:new_project_time_entries) { FactoryBot.create(:project, number_of_issues: 1, enabled_module_names: ['issue_tracking', 'time_entries', 'time_tracking']) }
    let(:time_entry_activity) { FactoryBot.create(:time_entry_activity, projects: [project_time_entries]) }
    let(:issue) { FactoryBot.create(:issue, project: project_time_entries) }
    let(:time_entry) { FactoryBot.create(:time_entry, issue: issue) }


    it 'copies issues with watchers' do
      issue_with_watchers

      expect { new_project.send(:copy_issues, project) }.to change(Watcher, :count).by(1)
    end

    it 'copies project without time entries' do
      time_entry

      expect {
        new_project_time_entries.send(:copy_issues, project_time_entries)
      }.not_to change(TimeEntry, :count)
    end

    it 'copies project with time entries' do
      time_entry

      expect {
        new_project_time_entries.copy_issues_with_easy_extensions(project_time_entries, {copy_time_entries: true, with_time_entries: true})
      }.to change(TimeEntry, :count).by(1)
    end

    it 'copies issues with tags' do
      issue_with_tags

      expect {
        expect {
          new_project.send(:copy_issues, project_with_tags)
        }.to change(ActsAsTaggableOn::Tagging, :count).by(1)
      }.not_to change(ActsAsTaggableOn::Tag, :count)
    end

    it 'copies versions with custom fields' do
      version_custom_field
      version.custom_field_values = { version_custom_field.id.to_s => 'test' }
      version.save
      expect(CustomValue.pluck(:value)).to eq(['test'])
      new_project.save
      expect {
        expect {
          new_project.send(:copy_versions, project)
          new_project.save
        }.to change(Version, :count).by(1)
      }.to change(CustomValue, :count).by(1)
      expect(CustomValue.pluck(:value)).to eq(['test', 'test'])
    end

    it 'copies issues with statuses' do
      default_status
      issue_with_watchers

      new_project.send(:copy_issues, project)
      expect(new_project.issues.first.status_id).to eq(status.id)
    end

    it 'copies issues with a group assignee' do
      with_settings(:issue_group_assignment => '1') do
        issue_with_group_assignee
        new_project.send(:copy_issues, project)

        expect(new_project.issues.first.assigned_to_id).to eq(group.id)
      end
    end
  end

  describe '#activities_per_role' do
    context 'with setting activity for role' do
      let(:project) { FactoryBot.create(:project) }
      let(:activity1) { FactoryBot.create(:time_entry_activity, position: 2) }

      let(:activity2) { FactoryBot.create(:time_entry_activity, position: 1) }
      let(:role) { User.current.roles_for_project(project).first }

      let!(:project_activity_role1) { FactoryBot.create(:project_activity_role, project_id: project.id, activity_id: activity1.id, role_id: role.id) }
      let!(:project_activity_role2) { FactoryBot.create(:project_activity_role, project_id: project.id, activity_id: activity2.id, role_id: role.id) }

      it 'sort by position' do
        with_easy_settings(enable_activity_roles: true) do
          expect(project.activities_per_role).to eq([activity2, activity1])
        end
      end
    end
  end

  describe '#members_list', logged: :admin do
    context 'should include correct items in correct order' do
      let(:project) { FactoryBot.create(:project, number_of_members: 2) }
      let(:role) { FactoryBot.create(:role, position: 999) }

      it 'sort by position ascending' do
        member1 = project.members.first
        member2 = project.members.second
        expect(project.members_list).to eq([member1, member2])
        member1.role_ids = [role.id]
        expect(project.members_list).to eq([member2, member1])
      end

      it 'should not list system users' do
        member1 = project.members.first
        project.members.second.user.update(easy_system_flag: true)
        expect(project.members_list(system_users: false)).to eq([member1])
      end
    end
  end

  context '#members_roles_with_non_member' do
    let(:project) { FactoryBot.create(:project) }
    it 'with non_member' do
      expect(project.members_roles_with_non_member).to include(Role.non_member)
    end
  end

  context 'with custom fields' do
    describe 'visible_custom_field_values' do
      let(:project) { FactoryBot.create(:project, number_of_issues: 0) }
      let(:role) { FactoryBot.create(:role) }
      let(:project_cf_for_project) { FactoryBot.create(:project_custom_field, is_for_all: false, visible: true) }
      let!(:project_cf) { FactoryBot.create(:project_custom_field, is_for_all: true, visible: true) }
      let!(:project_cf_for_role) { FactoryBot.create(:project_custom_field, is_for_all: true, visible: false, roles: [role]) }

      it 'contains visible custom fields'do
        expect(project.visible_custom_field_values(User.current).map(&:custom_field)).to contain_exactly(project_cf)
      end

      it 'refresh visibility after reassignments' do
        project.project_custom_field_ids = [project_cf_for_project.id]
        expect(project.visible_custom_field_values(User.current).map(&:custom_field)).to match_array [project_cf, project_cf_for_project]
        project.project_custom_field_ids = ['']
        expect(project.visible_custom_field_values(User.current).map(&:custom_field)).to match_array [project_cf]
      end
    end
  end

  context 'destroying' do
    describe '#scheduled_for_destroy?' do
      let(:project_not_to_be_destroyed) { FactoryBot.create(:project) }
      let(:project_to_be_destroyed) { FactoryBot.create(:project, destroy_at: Date.tomorrow) }

      it 'not scheduled for destroy' do
        expect(project_not_to_be_destroyed.scheduled_for_destroy?).to be_falsey
      end

      it 'scheduled for destroy' do
        expect(project_to_be_destroyed.scheduled_for_destroy?).to be_truthy
      end
    end

    describe '#schedule_for_destroy!' do
      let(:project) { FactoryBot.create(:project) }
      let!(:project_destroy_preferred_hour) { 2 }
      
      around(:each) do |ex|
        with_easy_settings(project_destroy_preferred_hour: project_destroy_preferred_hour) do
          Time.use_zone('Prague') do
            ex.run
          end
        end
      end

      it 'updates the attribute' do
        expect(project.scheduled_for_destroy?).to be_falsey
        project.schedule_for_destroy!
        project.reload
        expect(project.scheduled_for_destroy?).to be_truthy
      end

      it 'respects the hour setting' do
        project.schedule_for_destroy!
        expect(project.destroy_at.hour).to eq(project_destroy_preferred_hour)
      end

      it 'schedules for today' do
        travel_to DateTime.now.at_beginning_of_day do
          project.schedule_for_destroy!
          expect(project.destroy_at.day).to eq(DateTime.now.day)
        end
      end

      it 'schedules for tomorrow' do
        travel_to DateTime.now.change(hour: project_destroy_preferred_hour + 1) do
          project.schedule_for_destroy!
          expect(project.destroy_at.day).to eq(DateTime.tomorrow.day)
          expect(project.destroy_at.hour).to eq(project_destroy_preferred_hour)
        end
      end

      it 'creates a job' do
        project.schedule_for_destroy!
        expect(ProjectDestroyJob).to have_been_enqueued.with(project.id).at(project.destroy_at)
      end
    end
  end

end
