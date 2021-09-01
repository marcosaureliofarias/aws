require 'easy_extensions/spec_helper'

describe Issue do

  describe 'available_custom_fields', logged: true do
    let!(:issue_cf_forall) { FactoryGirl.create(:issue_custom_field, is_for_all: true) }
    let(:issue_cf) { FactoryGirl.create(:issue_custom_field, is_for_all: false) }
    let!(:tracker1) { FactoryGirl.create(:tracker) }
    let!(:tracker2) { FactoryGirl.create(:bug_tracker, issue_custom_fields: [issue_cf_forall, issue_cf]) }
    let(:project1) { FactoryGirl.create(:project, number_of_issues: 0, add_modules: ['issue_tracking']) }
    let(:project2) { FactoryGirl.create(:project, number_of_issues: 0, issue_custom_fields: [issue_cf], add_modules: ['issue_tracking']) }
    let(:issue1) { FactoryGirl.create(:issue, author: User.current, project: project1, tracker: tracker1) }
    let(:issue2) { FactoryGirl.create(:issue, author: User.current, project: project1, tracker: tracker2) }
    let(:issue3) { FactoryGirl.create(:issue, author: User.current, project: project2, tracker: tracker1) }
    let(:issue4) { FactoryGirl.create(:issue, author: User.current, project: project2, tracker: tracker2) }

    it 'gives right correctly sorted answers without cache' do
      expect(issue1.available_custom_fields.collect(&:id)).to eq([])
      expect(issue2.available_custom_fields.collect(&:id)).to eq([issue_cf_forall.id])
      expect(issue3.available_custom_fields.collect(&:id)).to eq([])
      expect(issue4.available_custom_fields.collect(&:id)).to eq([issue_cf_forall.id, issue_cf.id])
    end

    it 'gives right correctly sorted answers with cache' do
      Issue.load_available_custom_fields_cache([project1.id, project2.id])
      expect { Issue.load_available_custom_fields_cache([project1.id]) }.to_not raise_error #it does not fail to call cache twice with same ids
      expect(issue1.available_custom_fields.collect(&:id)).to eq([])
      expect(issue2.available_custom_fields.collect(&:id)).to eq([issue_cf_forall.id])
      expect(issue3.available_custom_fields.collect(&:id)).to eq([])
      expect(issue4.available_custom_fields.collect(&:id)).to eq([issue_cf_forall.id, issue_cf.id])
    end

    it 'loads all projects without project_ids' do
      project1; project2
      Issue.load_available_custom_fields_cache
      expect(Issue.available_custom_fields_from_cache(project1.id, tracker1.id).collect(&:id)).to eq([])
      expect(Issue.available_custom_fields_from_cache(project1.id, tracker2.id).collect(&:id)).to eq([issue_cf_forall.id])
      expect(Issue.available_custom_fields_from_cache(project2.id, tracker1.id).collect(&:id)).to eq([])
      expect(Issue.available_custom_fields_from_cache(project2.id, tracker2.id).collect(&:id)).to eq([issue_cf_forall.id, issue_cf.id])
    end

  end

  describe 'limit assignable users for project', logged: true do
    let(:user) { FactoryBot.create(:user) }
    let(:project) { FactoryBot.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0, members: [User.current, user]) }
    let(:issue) { FactoryBot.create(:issue, project: project, assigned_to_id: User.current.id) }

    after(:each) do
      allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_call_original
    end

    it 'allowed' do
      allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_return(false)
      issue.assigned_to_id = user.id
      expect(issue.valid?).to eq(true)
    end

    it 'not allowed' do
      allow_any_instance_of(User).to receive(:limit_assignable_users_for_project?).and_return(true)
      issue.assigned_to_id = user.id
      expect(issue.valid?).to eq(false)
    end
  end

  describe 'external user on assignable list', logged: :admin do
    let!(:external_easy_user_type) { FactoryBot.create(:easy_user_type, internal: false) }
    let!(:external_user) { FactoryBot.create(:user, easy_user_type: external_easy_user_type) }
    let!(:project) { FactoryBot.create(:project) }

    let!(:role) { FactoryBot.create(:role, name: 'client', limit_assignable_users: false, issues_visibility: 'own', assignable: true, permissions: [:view_issues, :edit_assigned_issue, :edit_own_issues]) }
    let!(:member) { FactoryBot.create(:member, project: project, user: external_user, roles: [role]) }

    let(:issue) { FactoryBot.create(:issue, project: project) }

    it 'is available with proper role' do
      expect(issue.assignable_users).to include(external_user)
    end
  end

  describe 'status change', :logged => :admin do
    let(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0) }
    let(:cf_datetime) { FactoryGirl.create(:issue_custom_field, field_format: 'datetime', is_for_all: true, is_filter: true, trackers: project.trackers, max_length: 25) }
    let(:issue) do
      _issue = FactoryGirl.create(:issue, project: project, due_date: Date.today)
      _issue.reload
      _issue.custom_field_values = {
          cf_datetime.id.to_s => { date: Date.today, hour: 10, minute: 10 },
      }
      _issue.save!
      _issue
    end
    let(:issue_status2) { FactoryGirl.create(:issue_status) }

    it 'datetime cf wont be changed' do
      original_value = issue.custom_field_value(cf_datetime)
      with_easy_settings(:skip_workflow_for_admin => true) do
        issue.safe_attributes = { 'status_id' => issue_status2.id.to_s }
        issue.save
      end
      reloaded = Issue.find_by(:id => issue.id)
      expect(reloaded.status_id).to eq(issue_status2.id)
      expect(issue.custom_field_value(cf_datetime)).to eq(original_value)
    end
  end

  describe 'advanced functionality', logged: :admin do
    let!(:issue1) { FactoryGirl.create(:issue, :with_journals).reload }
    let!(:issue2) { FactoryGirl.create(:issue, :with_journals).reload }
    let!(:issue3) { FactoryGirl.create(:issue, :with_journals).reload }
    let!(:closed_status) { FactoryGirl.create(:issue_status, :closed) }
    let!(:issue_with_description1) { FactoryGirl.create(:issue, :with_description) }
    let!(:issue_with_description2) { FactoryGirl.create(:issue, :with_description) }
    let!(:issue_without_description) { FactoryGirl.create(:issue) }

    let(:project_with_subprojects) { FactoryGirl.create(:project, :with_subprojects) }
    let(:project2) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking']) }

    it 'merges issues correctly into issue1' do
      issue1_journals_count = issue1.journals.size
      journals_count        = Journal.count
      issue2_journals_count = issue2.journals.size
      issue3_journals_count = issue3.journals.size

      Issue.easy_merge_and_close_issues([issue2, issue3], issue1)

      # increment by 1, add info journal to first issue
      expect(issue1.journals.size).to eq(1 + issue1_journals_count + issue2_journals_count + issue3_journals_count)

      # increment by 3, every merging add one info journal
      expect(Journal.count).to eq(3 + issue1_journals_count + issue2_journals_count * 2 + issue3_journals_count * 2)
    end

    it 'merges descriptions correctly' do
      Issue.easy_merge_and_close_issues([issue_with_description1, issue_with_description2], issue_with_description1)

      expect(issue_with_description1.description.to_s).to include(issue_with_description1.description.to_s)
      expect(issue_with_description1.description.to_s).to include(issue_with_description2.description.to_s)

      Issue.easy_merge_and_close_issues([issue_without_description, issue_with_description1], issue_without_description)

      expect(issue_without_description.description.to_s).to include(issue_without_description.description.to_s)
      expect(issue_without_description.description.to_s).to include(issue_with_description1.description.to_s)
    end

    context 'merges emails correctly' do
      let(:issue_to) { issue1.tap { |i| i.easy_email_to = 'test1@tst.com' } }
      let(:issue_cc) do
        issue1.tap { |i| i.easy_email_to = 'test1@tst.com'; i.easy_email_cc = 'test3@tst.com, test1@tst.com' }
      end
      it 'merge_to has easy_email_to' do
        allow(issue2).to receive(:easy_email_to).and_return('test2@tst.com')
        allow(issue2).to receive(:easy_email_cc).and_return('test3@tst.com, test4@tst.com')
        Issue.easy_merge_and_close_issues([issue2], issue_to)
        #easy_email_to shouldnt be changed
        expect(issue_to.easy_email_to).to eq('test1@tst.com')
        #easy_email_cc merged from all emails
        expect(issue_to.easy_email_cc.split(', ')).to match_array(['test2@tst.com', 'test3@tst.com', 'test4@tst.com'])
      end

      it 'merge_to has easy_email_to, easy_email_cc' do
        allow(issue2).to receive(:easy_email_to).and_return('test2@tst.com')
        allow(issue2).to receive(:easy_email_cc).and_return('test3@tst.com, test4@tst.com')
        Issue.easy_merge_and_close_issues([issue2], issue_cc)
        #easy_email_to shouldnt be changed
        expect(issue_cc.easy_email_to).to eq('test1@tst.com')
        #easy_email_cc merged from all emails, uniq,except email_to
        expect(issue_cc.easy_email_cc.split(', ')).to match_array(['test2@tst.com', 'test3@tst.com', 'test4@tst.com'])
      end
    end

    it 'moves issue between projects' do
      issue1.project = project2
      issue1.save
      expect(issue1.project).to eq project2
    end

    it 'creates correct issue relations from template with subprojects' do
      project_with_subprojects
      project_with_subprojects.reload
      issue_relation = IssueRelation.new

      first_subproject = project_with_subprojects.descendants.first
      last_subproject  = project_with_subprojects.descendants.last

      issue_relation.issue_from = first_subproject.issues.first
      issue_relation.issue_to   = last_subproject.issues.first

      with_settings(:cross_project_issue_relations => '1') do
        issue_relation.save

        templates = project_with_subprojects.create_project_templates(:copying_action => :creating_template, :copy_author => true)

        expect(templates[:unsaved].count).to eq 0
        template_subproject = templates[:saved].last.reload

        expect(IssueRelation.includes(:issue_from => :project).where(:projects => { :id => template_subproject.id }).count + IssueRelation.includes(:issue_to => :project).where(:projects => { :id => template_subproject.id }).count).to eq 1

        template_root = template_subproject.root.reload

        project_attributes = template_root.self_and_descendants.where("#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED).select([:id, :name]).collect { |p| { 'id' => p.id.to_s, 'name' => p.name } }

        new_project, saved_projects, unsaved_projects = template_root.project_with_subprojects_from_template('', project_attributes, { :copying_action => :creating_project, :copy_author => true, :easy_start_date => Date.today })

        expect(unsaved_projects.to_a.size).to eq 0
        template_subproject = saved_projects.last

        expect(IssueRelation.includes(:issue_from => :project).where(:projects => { :id => template_subproject.id }).count + IssueRelation.includes(:issue_to => :project).where(:projects => { :id => template_subproject.id }).count).to eq 1
      end
    end

    context 'replace %task_last_journal% comment with last non private journals' do
      def replace_last_journal_comment
        last_journal_comment       = issue1.journals.visible.where(:private_notes => false).with_notes.order(:created_on => :desc).first
        last_journal_comment_notes = issue1.format_journal_for_mail_template(last_journal_comment)

        expect(issue1.replace_last_non_private_comment('%task_last_journal%')).to eq last_journal_comment_notes
        if Redmine::Plugin.installed?(:easy_helpdesk)
          expect(issue1.easy_helpdesk_replace_tokens('%task_last_journal%')).to eq last_journal_comment_notes
        end

        expect(issue1.replace_last_non_private_comment('%task_last_journal%', last_journal_comment)).not_to eq last_journal_comment_notes
        if Redmine::Plugin.installed?(:easy_helpdesk)
          expect(issue1.easy_helpdesk_replace_tokens('%task_last_journal%', last_journal_comment)).not_to eq last_journal_comment_notes
        end
      end

      it 'replaces the last journal' do
        replace_last_journal_comment
      end

      it 'replaces the last non private journal' do
        last_journal_comment = issue1.journals.visible.where(:private_notes => false).with_notes.order(:created_on => :desc).first
        last_journal_comment.update_attribute(:private_notes, true)
        replace_last_journal_comment
      end
    end
  end

  context 'workflow', :logged => true do
    include_context 'workflows_support'
    before(:each) do
      project
      role = User.current.reload.roles.first
      role.add_permission! :edit_issues
      WorkflowTransition.create!(:role_id => role.id, :tracker_id => tracker.id, :old_status_id => issue_status1.id, :new_status_id => issue_status2.id)
      WorkflowPermission.create!(:role_id => role.id, :tracker_id => tracker.id, :old_status_id => issue_status1.id, :field_name => 'assigned_to_id', :rule => 'readonly')
      WorkflowPermission.create!(:role_id => role.id, :tracker_id => tracker.id, :old_status_id => issue_status2.id, :field_name => 'assigned_to_id', :rule => 'required')
      issue.reload
    end

    it 'after status change read only' do
      issue.safe_attributes = { 'assigned_to_id' => user.id.to_s, 'status_id' => issue_status1.id.to_s }
      expect(issue.assigned_to_id).not_to eq(user.id)
    end

    it 'after status change required' do
      issue.safe_attributes = { 'assigned_to_id' => user.id.to_s, 'status_id' => issue_status2.id.to_s }
      expect(issue.assigned_to_id).to eq(user.id)
    end
  end

  context 'api_decorator', logged: true do
    let!(:issue) { FactoryGirl.create(:issue, :with_journals) }

    it 'Output correct XMl' do
      xml = EasyApiDecorators::Issue.new(issue, ['journals']).to_xml
      expect { Hash.from_xml(xml) }.to_not raise_error(Exception)
      expect(xml).to include(issue.subject)
      expect(xml).to include(issue.journals.first.notes)
    end

    it 'Output correct JSON' do
      json = EasyApiDecorators::Issue.new(issue, ['journals']).to_json
      expect { JSON.parse(json) }.to_not raise_error(Exception)
      expect(json).to include(issue.subject)
      expect(json).to include(issue.journals.first.notes)
    end

    it 'Output correct XMl' do
      xml = EasyApiDecorators::Issue.new(issue, nil).to_xml
      expect { Hash.from_xml(xml) }.to_not raise_error(Exception)
      expect(xml).to include(issue.subject)
      expect(xml).not_to include(issue.journals.first.notes)
    end

    it 'Output correct JSON' do
      json = EasyApiDecorators::Issue.new(issue, nil).to_json
      expect { JSON.parse(json) }.to_not raise_error(Exception)
      expect(json).to include(issue.subject)
      expect(json).not_to include(issue.journals.first.notes)
    end
  end

  context 'With distributed tracker', logged: true do
    let!(:project) { FactoryBot.create(:project, trackers: [tracker, distributed_tracker]) }
    let(:distributed_tracker) { FactoryBot.create(:tracker, easy_distributed_tasks: true) }
    let(:tracker) { FactoryBot.create(:tracker) }
    let(:issue) { FactoryBot.create(:issue, project: project, tracker: tracker) }
    let(:distributed_issue) { FactoryBot.build(:issue, project: project, author: User.current, tracker: distributed_tracker) }
    let(:existing_distributed_issue) { FactoryBot.create(:issue, project: project, tracker: distributed_tracker, easy_distributed_tasks: distributed_params) }
    let(:empty_distributed_params) { { assigned_to_ids: [''], ests: [''] } }
    let(:distributed_params) { { assigned_to_ids: [User.current.id], ests: ['2'] } }

    it 'requires distributed params for new record' do
      # new record without distributed params
      expect { distributed_issue.save }.not_to change(Issue, :count)

      distributed_issue.easy_distributed_tasks = empty_distributed_params
      # new record with empty distributed params
      expect { distributed_issue.save }.not_to change(Issue, :count)

      distributed_issue.easy_distributed_tasks = distributed_params
      # new record with distributed params
      expect { distributed_issue.save }.to change(Issue, :count).by(2)
    end

    it 'allows saving of exiting distributed tasks without distributed params' do
      existing_distributed_issue.remove_instance_variable(:@easy_distributed_tasks)

      expect { existing_distributed_issue.save }.not_to raise_exception
    end

    it 'does not allow setting of distributed tracker to existing tasks' do
      issue.safe_attributes = {
          tracker: distributed_tracker
      }

      expect(issue.tracker).not_to eq(distributed_tracker)
    end
  end

  describe '#copy_from', logged: true do
    context 'with datetime custom field' do
      let(:datetime_cf) { FactoryBot.create(:issue_custom_field, field_format: 'datetime') }
      let(:custom_value) { double(CustomValue, custom_field: datetime_cf, custommized: issue, value: '2018-11-13 18:00:00') }
      let(:issue) { FactoryBot.create(:issue) }

      it 'copies custom value with time zone adjustment' do
        allow_any_instance_of(Issue).to receive(:available_custom_fields).and_return(Array(datetime_cf))
        allow_any_instance_of(Issue).to receive(:custom_values).and_return(Array(custom_value))
        issue.instance_variable_set(:@custom_field_values, nil)

        with_user_pref(time_zone: 'Beijing') do # +08:00
          expect(Issue.new.copy_from(issue).custom_field_values.first.value).to eq('2018-11-13 18:00:00')
        end
      end

    end
  end

  context 'close subtasks', logged: :admin do
    let(:child_issue) { FactoryBot.create(:issue, :child_issue) }
    let(:closed_status) { FactoryBot.create(:issue_status, is_closed: true) }

    it 'update attributes' do
      with_easy_settings(close_subtask_after_parent: true) do
        parent           = child_issue.parent
        parent.status_id = closed_status.id
        expect(parent.save).to eq(true)
        [parent, child_issue].each do |issue|
          issue.reload
          expect(issue.status_id).to eq(closed_status.id)
          expect(issue.easy_last_updated_by).to eq(User.current)
          expect(issue.easy_closed_by).to eq(User.current)
          expect(issue.easy_status_updated_on).not_to eq(nil)
          expect(issue.closed_on).not_to eq(nil)
        end
      end
    end
  end

  it 'set tags', logged: :admin do
    FactoryBot.create(:issue, tag_list: 'testtag')
    expect(ActsAsTaggableOn::Tag.joins(:taggings).where(:taggings => { :context => 'tags' }).distinct.pluck(:name)).to include('testtag')
  end

  describe 'validations', logged: :admin do
    it 'should require easy_email_to before sending mail' do
      issue = FactoryBot.create(:issue, easy_email_to: nil)
      allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(true)
      issue.send_to_external_mails = '1'
      expect(issue.valid?).to be_falsey
      expect(issue.errors[:easy_email_to]).to include('cannot be blank')
    end

    context 'do not allow close if subtasks opened' do
      include_context 'easy_do_not_allow_close_if_subtasks_opened'
      it 'cannot close parent if subtasks' do
        child_issue
        parent_issue.reload
        parent_issue.update(status_id: closed_status.id)
        expect(parent_issue.valid?).to be_falsey
        expect(parent_issue.errors[:base]).to include(I18n.t(:error_cannot_close_issue_due_to_subtasks, issues: '\n' + child_issue.to_s))
      end

      it 'cannot add subtask if parent closed' do
        parent_issue.update_attribute(:status_id, closed_status.id)
        issue.update(parent_issue_id: parent_issue.id)
        expect(issue.valid?).to be_falsey
        expect(issue.errors[:base]).to include(I18n.t(:error_cannot_add_subtask_to_parent_due_to_settings))
      end
    end
  end

  context '#addable_watchers' do
    let(:issue) { FactoryBot.create(:issue) }

    it 'regular', logged: true do
      expect(issue.addable_watcher_users).to be_empty
    end

    it 'admin', logged: :admin do
      expect(issue.addable_watcher_users).to be_empty
    end
  end

  context '#notified_watchers' do
    let(:group) { FactoryBot.create(:group, users: [user]) }
    let(:user) { FactoryBot.create(:user, mail_notification: 'all', admin: true) }
    let(:user2) { FactoryBot.create(:user, mail_notification: 'all', admin: true) }
    let(:user3) { FactoryBot.create(:user, mail_notification: 'none', admin: true) }

    it 'users without notifications' do
      issue = FactoryBot.create(:issue, watcher_user_ids: [user3.id])
      expect(issue.send(:notified_watchers)).to be_empty
    end

    it 'users' do
      issue = FactoryBot.create(:issue, watcher_user_ids: [user.id])
      expect(issue.send(:notified_watchers)).to eq([user])
    end

    it 'groups' do
      issue = FactoryBot.create(:issue, watcher_group_ids: [group.id])
      expect(issue.send(:notified_watchers)).to eq([user])
    end

    it 'groups + users' do
      issue = FactoryBot.create(:issue, watcher_group_ids: [group.id], watcher_user_ids: [user2.id])
      expect(issue.send(:notified_watchers)).to match_array([user, user2])
    end

    context 'no_notified_if_issue_closing' do
      before(:each) do
        allow_any_instance_of(UserPreference).to receive(:no_notified_if_issue_closing).and_return(true)
      end

      it 'open' do
        issue = FactoryBot.create(:issue, watcher_user_ids: [user.id])
        expect(issue.send(:notified_watchers)).to match_array([user])
      end

      it 'closed' do
        issue = FactoryBot.create(:issue, status: FactoryBot.create(:issue_status, :closed), watcher_user_ids: [user.id])
        expect(issue.send(:notified_watchers)).to be_empty
      end
    end
  end

  describe '#get_notified_users_for_issue_edit' do
    let(:assignee) { FactoryBot.create(:user, mail_notification: 'all') }
    let(:issue) { FactoryBot.create(:issue, assigned_to: assignee) }

    let(:journal_with_notes) { FactoryBot.create(:journal, journalized: issue, notes: 'Notes 1', private_notes: false) }
    let(:journal_with_details) { FactoryBot.create(:journal, journalized: issue, notes: '', private_notes: false) }
    let(:private_journal) { FactoryBot.create(:journal, journalized: issue, notes: 'Notes 2', private_notes: true) }
    let(:private_journal_without_details_and_notes) { FactoryBot.create(:journal, journalized: issue, notes: '', private_notes: true) }

    let(:custom_field) { FactoryBot.create(:issue_custom_field, mail_notification: 'true') }
    let(:journal_detail) { FactoryBot.create(:journal_detail, journal: journal_with_details, property: 'cf', prop_key: custom_field.id) }

    it 'public notes' do
      expect(issue.get_notified_users_for_issue_edit(journal_with_notes)).to eq([assignee])
    end

    it 'journal with details' do
      journal_detail
      expect(issue.get_notified_users_for_issue_edit(journal_with_details.reload)).to eq([assignee])
    end

    it 'user with permission' do
      Role.non_member.add_permission! :view_private_notes
      expect(issue.get_notified_users_for_issue_edit(private_journal)).to eq([assignee])
    end

    it 'user without permission' do
      expect(issue.get_notified_users_for_issue_edit(private_journal)).to eq([])
    end

    it 'private journal without notes and details' do
      Role.non_member.add_permission! :view_private_notes
      expect(issue.get_notified_users_for_issue_edit(private_journal_without_details_and_notes)).to eq([])
    end

    context 'previous assignee', logged: true do
      let(:issue_assigned_to_me) { FactoryBot.create(:issue, assigned_to: User.current) }

      before(:each) do
        allow(issue).to receive(:last_user_assigned_to).and_return(User.current)
      end

      it 'is notified if wants to be notified' do
        with_user_pref('no_notified_as_previous_assignee' => false) do
          expect(issue.get_notified_users_for_issue_edit(journal_with_notes)).to include(User.current)
        end
      end

      it 'is not notified if doesn\'t want to be notified' do
        with_user_pref('no_notified_as_previous_assignee' => true) do
          expect(issue.get_notified_users_for_issue_edit(journal_with_notes)).not_to include(User.current)
        end
      end

      it 'is still notified if the current assignee' do
        with_user_pref('no_notified_as_previous_assignee' => true) do
          expect(issue_assigned_to_me.get_notified_users_for_issue_edit(journal_with_notes)).to include(User.current)
        end
      end
    end

    context 'with notify_children' do
      let!(:child_assignee) { FactoryBot.create(:user, mail_notification: 'all') }
      let!(:child_issue) { FactoryBot.create(:issue, assigned_to: child_assignee, parent_id: issue.id) }

      it 'send notification to the assignee of child_issue' do
        journal_with_notes.notify_children = true

        expect(issue.get_notified_users_for_issue_edit(journal_with_notes)).to contain_exactly(assignee, child_assignee)
      end
    end
  end

end
