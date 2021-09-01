require 'easy_extensions/spec_helper'

describe IssuesController, :logged => :admin do

  let(:project) { FactoryBot.create(:project) }
  let(:project_with_all_modules) { FactoryBot.create(:project, add_modules: Redmine::AccessControl.available_project_modules) }
  let(:version) { FactoryBot.create(:version) }
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:issue_with_all_modules) { FactoryBot.create(:issue, project: project_with_all_modules) }
  let(:issues) { FactoryBot.create_list(:issue, 3, project: project) }
  let(:time_entry_activity) { FactoryBot.create(:time_entry_activity, projects: [project]) }
  let(:time_entry) { FactoryBot.create(:time_entry, issue: issue, project: project) }
  let(:issue_with_description) { FactoryBot.create(:issue, project: project,
                                                    description:     '<p><h1>TEST</h1></p><p><a href=https://test.com>test</a></p>') }

  describe 'GET show' do
    render_views

    it 'html' do
      get :show, :params => { :id => issue_with_description }
      expect(response).to be_successful
    end

    it 'all modules' do
      get :show, params: { id: issue_with_all_modules }
      expect(response).to be_successful
    end

    context 'formatted custom field' do
      let!(:custom_field_long_formatted_text) { FactoryGirl.create(:issue_custom_field, :field_format => 'text', :text_formatting => 'full', :trackers => [issue.tracker]) }

      it 'show issue detail' do
        get :show, :params => { :id => issue.id }
        expect(response).to be_successful
      end
    end

    context 'EXPORTS' do
      it 'pdf detail' do
        get :show, :params => { :format => 'pdf', :id => issue_with_description }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/pdf')
      end

      it 'pdf detail with html description' do
        with_settings({ 'text_formatting' => 'HTML' }) do
          get :show, :params => { :format => 'pdf', :id => issue_with_description }
        end
        expect(response).to be_successful
        expect(response.content_type).to eq('application/pdf')
      end

      it 'pdf detail with external image' do
        stub_request(:get, "https://www.calculoid.com/images/Logo_Calculoid.svg?v=2").
          with(
            headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'User-Agent'=>'Ruby'
           }).
         to_return(status: 200, body: '<svg aria-hidden="true" focusable="false" data-prefix="fas"
data-icon="copy" class="svg-inline--fa fa-copy fa-w-14" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0
 448 512"><path fill="currentColor" d="M320 448v40c0 13.255-10.745 24-24 24H24c-13.255 0-24-10.745-24-24V120c0-13.255
 10.745-24 24-24h72v296c0 30.879 25.121 56 56 56h168zm0-344V0H152c-13.255 0-24 10.745-24 24v368c0 13.255 10.745 24 24
 24h272c13.255 0 24-10.745 24-24V128H344c-13.2 0-24-10.8-24-24zm120.971-31.029L375.029 7.029A24 24 0 0 0 358.059
 0H352v96h96v-6.059a24 24 0 0 0-7.029-16.97z"></path></svg>', headers: {})

        issue_with_description.update_column(:description, '<p><img alt="EasyRedmine_Logo" src="https://www.calculoid.com/images/Logo_Calculoid.svg?v=2" /></p>')
        with_settings({ 'text_formatting' => 'HTML' }) do
          get :show, params: { format: 'pdf', id: issue_with_description }
        end
        expect(response).to be_successful
        expect(response.content_type).to eq('application/pdf')
      end
    end
  end

  describe 'GET index' do
    let(:project1) { FactoryGirl.create(:project, parent: project) }
    let(:issue1) { FactoryGirl.create(:issue, project: project1) }
    let(:project2) { FactoryGirl.create(:project, parent: project) }
    let(:issue2) { FactoryGirl.create(:issue, project: project2) }

    context 'EXPORTS' do
      render_views

      before(:each) { issues }

      it 'exports index to pdf with description' do
        issue_with_description
        with_settings({ 'text_formatting' => 'HTML' }) do
          get :index, :params => { :format => 'pdf', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        end
        expect(response).to be_successful
        expect(response.content_type).to eq('application/pdf')
      end

      it 'exports index to pdf' do
        get :index, :params => { :format => 'pdf', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(assigns(:issues)).not_to be_nil
        expect(response.content_type).to eq('application/pdf')
      end

      it 'exports project index to pdf' do
        get :index, :params => { :project_id => project.id, :format => 'pdf', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(assigns(:issues)).not_to be_nil
        expect(response.content_type).to eq('application/pdf')
      end

      it 'exports to xlsx' do
        get :index, :params => { :format => 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      it 'exports to csv' do
        get :index, :params => { :format => 'csv', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(response.content_type).to include('text/csv')
      end

      it 'renders atom format' do
        get :index, :params => { :format => 'atom' }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/atom+xml')
        expect(assigns(:items)).not_to be_nil
        expect(assigns(:items).first).to be_a(Issue)
      end

      it 'renders atom format detail with tags' do
        i = issues.first
        i.init_journal(User.current)
        i.current_journal.details << JournalDetail.new(property: 'tags', prop_key: 'tag_list', old_value: [].to_json, value: ['mytag'].to_json)
        expect { i.save }.to change(Journal, :count).by(1)
        get :show, params: { id: i.id, format: 'atom' }
        expect(response).to be_successful
        expect(response.body).to include('mytag')
      end

      it 'renders ics format' do
        get :index, :params => { :format => 'ics' }
        expect(response).to be_successful
        expect(response.content_type).to include('text/calendar')
        expect(response.body).not_to be_blank
      end
    end

    context 'API' do
      render_views
      let(:settings) { HashWithIndifferentAccess.new(:entity_type => 'User', :entity_attribute => 'link_with_name') }
      let(:easy_lookup_custom_field) { FactoryGirl.create(:issue_custom_field, :field_format => 'easy_lookup', :settings => settings, :multiple => true, :trackers => [issue.tracker]) }

      it 'renders issues to JSON' do
        issue_count = project.issues.count
        get :index, :params => { format: 'json', include: ['total_count'] }
        expect(response).to be_successful
        expect(json).to have_key(:issues)
        expect(json[:total_count]).to eq(issue_count)
        expect(json[:issues].count).to eq(issue_count)
      end

      it 'renders issues to JSON with lookup' do
        easy_lookup_custom_field; issue.reload
        issue.safe_attributes = { 'custom_field_values' => { easy_lookup_custom_field.id.to_s => [User.current.id.to_s] } }
        issue.save; issue.reload
        get :index, :params => { :format => 'json' }
        expect(response).to be_successful
        expect(response.body).to include(User.current.name)
      end

      context 'filtering by created_on' do
        let(:in_range_issue1) { FactoryBot.create(:issue) }
        let(:in_range_issue2) { FactoryBot.create(:issue) }
        let(:out_range_issue) { FactoryBot.create(:issue) }

        context 'time request' do
          it '=' do
            in_range_issue1.update_columns(created_on: '2019-09-02 12:40:25 +00')
            get :index, params: { format: 'xml', created_on: '=2019-09-02T12:40:25Z', set_filter: '1' }
            expect(assigns(:entities).count).to eq(1)
          end

          it '>=' do
            in_range_issue1.update_columns(created_on: '2019-09-02 12:40:25 +00')
            in_range_issue2.update_columns(created_on: '2019-09-02 12:40:26 +00')
            out_range_issue.update_columns(created_on: '2019-09-02 12:40:24 +00')
            get :index, params: { format: 'xml', created_on: '>=2019-09-02T12:40:25Z', set_filter: '1' }
            expect(assigns(:entities).count).to eq(2)
            expect(assigns(:entities)).to include(in_range_issue1, in_range_issue2)
          end

          it '<=' do
            in_range_issue1.update_columns(created_on: '2019-09-02 12:40:25 +00')
            in_range_issue2.update_columns(created_on: '2019-09-02 12:40:24 +00')
            out_range_issue.update_columns(created_on: '2019-09-02 12:40:26 +00')
            get :index, params: { format: 'xml', created_on: '<=2019-09-02T12:40:25Z', set_filter: '1' }
            expect(assigns(:entities).count).to eq(2)
            expect(assigns(:entities)).to include(in_range_issue1, in_range_issue2)
          end

          it '><' do
            in_range_issue1.update_columns(created_on: '2019-09-02 12:40:25 +00')
            in_range_issue2.update_columns(created_on: '2019-09-02 12:40:27 +00') # out of range 2
            out_range_issue.update_columns(created_on: '2019-09-02 12:40:24 +00')
            get :index, params: { format: 'xml', created_on: '><2019-09-02T12:40:25Z|2019-09-02T12:40:26Z', set_filter: '1' }
            expect(assigns(:entities).count).to eq(1)
            expect(assigns(:entities)).to include(in_range_issue1)
          end

        end
        context 'date request' do
          it '=' do
            in_range_issue1.update_columns(created_on: '2019-09-02 12:40:25 +00')
            get :index, params: { format: 'xml', created_on: '=2019-09-02', set_filter: '1' }
            expect(assigns(:entities).count).to eq(1)
          end

          it '>=' do
            in_range_issue1.update_columns(created_on: '2019-09-03 12:40:25 +00')
            in_range_issue2.update_columns(created_on: '2019-09-02 12:40:26 +00')
            out_range_issue.update_columns(created_on: '2019-09-01 12:40:24 +00')
            get :index, params: { format: 'xml', created_on: '>=2019-09-02', set_filter: '1' }
            expect(assigns(:entities).count).to eq(2)
            expect(assigns(:entities)).to include(in_range_issue1, in_range_issue2)
          end

          it '<=' do
            in_range_issue1.update_columns(created_on: '2019-09-01 12:40:25 +00')
            in_range_issue2.update_columns(created_on: '2019-09-02 12:40:24 +00')
            out_range_issue.update_columns(created_on: '2019-09-03 12:40:26 +00')
            get :index, params: { format: 'xml', created_on: '<=2019-09-02', set_filter: '1' }
            expect(assigns(:entities).count).to eq(2)
            expect(assigns(:entities)).to include(in_range_issue1, in_range_issue2)
          end
        end
      end
    end

    it 'creates repeating task with right date shift' do
      with_time_travel(0, :now => Date.new(2015, 2, 4).to_time) do
        issue_attrs = FactoryGirl.attributes_for(:issue, :recurring_monthly, :project => project).deep_dup.merge!({ project_id: project.id, easy_next_start: Date.today.next_month.beginning_of_month, start_date: Date.today.beginning_of_month, due_date: nil })
        issue_attrs[:easy_repeat_settings].merge!({ 'simple_period' => 'custom', 'endtype_count_x' => 3, 'period' => 'monthly', 'monthly_period' => 1, 'monthly_option' => 'xth', 'monthly_day' => '1', 'endtype' => 'count', 'create_now' => 'all' })
        post :create, :params => { :issue => issue_attrs }

        # expect( response ).to have_http_status(302)
        expect(response).to redirect_to(issue_path(assigns[:issue]))

        recurring = Issue.easy_repeating.first
        recurred  = recurring.relations_from.collect { |rel| rel.issue_to }

        expect(recurred.count).to eq(3)

        expect(recurred.select { |recc| recc.start_date == Date.today.next_month.beginning_of_month }.count).to eq(1)
      end
    end

    context 'new' do
      render_views

      it 'with all modules' do
        get :new, params: { project_id: project_with_all_modules }
        expect(response).to be_successful
      end

      it 'issues without available trackers' do
        project.trackers = []
        get :new, params: { :project_id => project.id }
        expect(response).to have_http_status(500)
        expect(response).to render_template 'common/error'
      end
    end

    it 'subproject is not' do
      issue1; issue2
      get :index, params: { project_id: project.id, f: { subproject_id: "!#{project2.id}" } }
      project_ids = assigns[:issues].map(&:project_id)
      expect(project_ids).to include (project1.id)
      expect(project_ids).not_to include (project2.id)
    end

  end

  context 'updates issue with spent time' do
    it 'hours' do
      expect {
        put :update, params: { id: issue, time_entry: { hours: 5, activity_id: time_entry_activity }, issue: { description: 'testing' } }
      }.to change(TimeEntry, :count).by(1)
      issue.reload
      expect(issue.description).to eq('testing')
      expect(issue.time_entries).not_to be_blank
    end

    it 'time range' do
      expect {
        put :update, params: { id: issue, issue: { subject: 'updated' }, time_entry: { activity_id: time_entry_activity, easy_time_entry_range: { from: '01:00', to: '02:00' } } }
      }.to change(TimeEntry, :count).by(1)
      issue.reload
      expect(issue.time_entries.first.hours).to eq(1)
      expect(issue.subject).to eq('updated')
    end

    it 'invalid time range' do
      expect {
        put :update, params: { id: issue, issue: { subject: 'updated' }, time_entry: { activity_id: time_entry_activity, easy_time_entry_range: { from: '', to: '' } } }
      }.to change(TimeEntry, :count).by(0)
      issue.reload
      expect(issue.subject).to eq('updated')
    end

    it 'hours & minutes' do
      expect {
        put :update, params: { id: issue, time_entry: { activity_id: time_entry_activity, hours_hour: '1', hours_minute: '30' } }
      }.to change(TimeEntry, :count).by(1)
      issue.reload
      expect(issue.time_entries.first.hours).to eq(1.5)
    end
  end

  it 'attachments api' do
    attachment = FactoryBot.create(:attachment, file: 'content', container: nil)
    put :update, params: { id: issue, issue: { uploads: [{ token: attachment.token, filename: 'xxx.txt', content_type: 'text/plain' }] } }
    issue.reload
    expect(issue.attachments).to eq([attachment])
  end

  it 'create invalid issue (fixed version without project)' do
    expect {
      post :create, :params => { :issue => { :fixed_version_id => version.id } }
    }.not_to raise_exception
  end

  it 'assignee none' do
    post :create, params: { issue: {project_id: project.id, subject: 'test', assigned_to_id: 'none'}, format: 'json' }
    expect(response).to be_successful
    expect(assigns(:issue).assigned_to_id).to eq(nil)
  end

  it 'create issue + extend flash message' do
    project

    expect {
      post :create, :params => { :issue => { :project_id => project.id, :subject => 'test' } }
    }.to change(Issue, :count).by(1)

    with_settings(:bcc_recipients => false) do
      expect {
        post :create, :params => { :issue => { :project_id => project.id, :subject => 'test' } }
      }.to change(Issue, :count).by(1)
    end
  end

  context 'period days filter', :admin => true do
    render_views

    before(:each) { issues.each_with_index { |issue, i| issue.update_column(:due_date, Date.today - i.days) } }

    it '1 day' do
      get :index, :params => { :format => 'json', :set_filter => '1', :due_date => 'from_m_to_n_days|1|1' }
      expect(response).to be_successful
      expect(assigns(:entities).count).to eq(2)
    end

    it '5 days' do
      get :index, :params => { :format => 'json', :set_filter => '1', :due_date => 'from_m_to_n_days|5|1' }
      expect(response).to be_successful
      expect(assigns(:entities).count).to eq(issues.count)
    end
  end

  context 'bulk update', :logged => :admin do
    render_views

    let(:issue) { FactoryGirl.create(:issue, :description => 'issue1', :assigned_to_id => nil) }
    let(:issue2) { FactoryGirl.create(:issue, :description => 'issue2', :assigned_to_id => User.current.id) }
    let(:issue3) { FactoryGirl.create(:issue, :description => 'issue3', :parent => issue2) }
    let(:test_user) { FactoryGirl.create(:user) }

    it 'author' do
      put :bulk_update, :params => { :ids => [issue.id, issue2.id], :issue => { :author_id => test_user.id } }
      i1 = Issue.find(issue.id); i2 = Issue.find(issue2.id)
      expect(i1.author_id).to eq(test_user.id)
      expect(i2.author_id).to eq(test_user.id)
    end

    it 'invalid author' do
      put :bulk_update, :params => { :ids => [issue.id, issue2.id], :issue => { :author_id => nil } }
      i1 = Issue.find(issue.id); i2 = Issue.find(issue2.id)
      expect(i1.author_id).not_to eq(nil)
      expect(i2.author_id).not_to eq(nil)
    end

    context 'assignee' do
      it 'unassign' do
        expect(issue.assigned_to_id).to eq(nil)
        expect(issue2.assigned_to_id).to eq(User.current.id)
        put :bulk_update, params: { issue: {project_id: project.id, assigned_to_id: 'none'}, ids: [issue.id, issue2.id], format: 'json' }
        expect(issue.reload.assigned_to_id).to eq(nil)
        expect(issue2.reload.assigned_to_id).to eq(nil)
      end

      it 'no change' do
        expect(issue.assigned_to_id).to eq(nil)
        expect(issue2.assigned_to_id).to eq(User.current.id)
        put :bulk_update, params: { issue: {project_id: project.id, assigned_to_id: ''}, ids: [issue.id, issue2.id], format: 'json' }
        expect(issue.reload.assigned_to_id).to eq(nil)
        expect(issue2.reload.assigned_to_id).to eq(User.current.id)
      end
    end

    it 'copy subtasks' do
      issue3
      expect {
        put :bulk_update, params: { ids: [issue2.id], copy_subtasks: '1', copy: '1', issue: { custom_field_values: { '1' => 'value' } }, format: 'json' }
        expect(response).to be_successful
      }.to change(Issue, :count).by(2)
    end

    context 'merge' do
      let(:issue_status) { FactoryGirl.create(:issue_status, :is_closed => true) }

      before(:each) do
        issue; issue2; issue_status
      end

      after(:each) do
        i1 = Issue.find(issue.id); i2 = Issue.find(issue2.id)
        expect(i1.closed?).to eq(true)
        expect(i2.closed?).to eq(false)
        expect(i2.description).to include('issue1')
        expect(i2.description).to include('issue2')
        expect([404, 500].include?(response.status)).to eq(false)
      end

      it 'html' do
        put :bulk_update, :params => { :ids => [issue.id], :issue => { :merge_to_id => issue2.id }, :merge => '1' }
      end

      it 'json' do
        put :bulk_update, :params => { :ids => [issue.id], :issue => { :merge_to_id => issue2.id }, :merge => '1', :format => 'json' }
      end
    end

    context 'multiple projects' do
      let(:project1_user) { FactoryBot.create(:user) }
      let(:project2_user) { FactoryBot.create(:user) }
      let(:shared_user) { FactoryBot.create(:user) }
      let(:project1) { FactoryBot.create(:project, members: [project1_user, shared_user]) }
      let(:project2) { FactoryBot.create(:project, members: [project2_user, shared_user]) }
      let(:project1_issue) { FactoryBot.create(:issue, project: project1, author: project1_user, assigned_to: project1_user) }
      let(:project2_issue) { FactoryBot.create(:issue, project: project2, author: project2_user, assigned_to: project2_user) }

      it 'user has access to all projects' do
        put :bulk_update, params: { ids: [project1_issue.id, project2_issue.id], issue: { assigned_to_id: shared_user.id }, format: 'json' }
        expect(response).to be_successful
        i1 = Issue.find(project1_issue.id); i2 = Issue.find(project2_issue.id)
        expect(i1.assigned_to).to eq(shared_user)
        expect(i2.assigned_to).to eq(shared_user)
      end

      it 'user has access to one project only' do
        put :bulk_update, params: { ids: [project1_issue.id, project2_issue.id], issue: { assigned_to_id: project1_user.id }, format: 'json' }
        expect(response).not_to be_successful
        i1 = Issue.find(project1_issue.id); i2 = Issue.find(project2_issue.id)
        expect(i1.assigned_to).to eq(project1_user)
        expect(i2.assigned_to).not_to eq(project1_user)
      end
    end
  end

  context 'permissions', :logged => true do
    let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking'], :members => [User.current]) }
    let(:issue) { FactoryGirl.create(:issue, :project => project, :author => User.current) }

    it 'with edit_own_issue' do
      role = User.current.roles.first
      role.remove_permission!(:edit_issues)
      role.add_permission!(:edit_own_issues)
      role.reload
      put :update, :params => { :id => issue.id, :issue => { :description => 'testing' } }
      issue.reload
      expect(issue.description).to eq('testing')
    end

    it 'with edit_assigned_issue' do
      role = User.current.roles.first
      role.remove_permission!(:edit_issues)
      role.add_permission!(:edit_assigned_issue)
      role.reload
      put :update, :params => { :id => issue.id, :issue => { :description => 'testing' } }
      issue.reload
      expect(issue.description).to eq('testing')
    end

    it 'with edit_issues' do
      role = User.current.roles.first
      role.add_permission!(:edit_issues)
      role.remove_permission!(:edit_own_issues)
      role.reload
      put :update, :params => { :id => issue.id, :issue => { :description => 'testing' } }
      issue.reload
      expect(issue.description).to eq('testing')
    end

    it 'without edit_issues' do
      role = User.current.roles.first
      role.remove_permission!(:edit_issues, :add_issue_notes, :edit_own_issues)
      role.reload
      put :update, :params => { :id => issue.id, :issue => { :description => 'testing' } }
      issue.reload
      expect(issue.description).not_to eq('testing')
    end
  end

  context 'journals' do

    let(:issue_category) { FactoryGirl.create(:issue_category, :project => project) }
    let!(:issue_parent1) { FactoryGirl.create(:issue, :project => project, :due_date => nil) }
    let!(:issue_parent2) { FactoryGirl.create(:issue, :project => project, :due_date => nil) }

    render_views

    it 'should not create journal detail when a date column is changed' do
      expect { put :update, :params => { :id => issue, :issue => { :due_date => User.current.today + 1.day } } }.to change(JournalDetail, :count).by(1)
      expect { put :update, :params => { :id => issue, :issue => { :description => 'test1' } } }.to change(JournalDetail, :count).by(1)
      expect { put :update, :params => { :id => issue, :issue => { :description => 'test2', :due_date => User.current.today + 2.days } } }.to change(JournalDetail, :count).by(2)
    end

    it 'renders reflection journals' do
      journal                 = FactoryGirl.create(:journal)
      issue                   = issues.first
      issue.easy_closed_by_id = issue.author_id
      issue.fixed_version     = version
      issue.parent_id         = issues.second
      issue.activity          = time_entry_activity
      issue.category          = issue_category
      issue.journals << journal

      reflection_columns = %w(project_id parent_id status_id tracker_id assigned_to_id priority_id category_id fixed_version_id author_id activity_id easy_closed_by_id) + issue.journalized_options[:format_detail_reflection_columns]
      reflection_columns.each do |column|
        JournalDetail.create(property: 'attr', prop_key: column, old_value: issue.try(column), value: issue.try(column), journal: journal)
      end
      get :show, :params => { :id => issue.id, :format => :html }
      expect(response).to be_successful
    end

    it 'journal to parent task when it changes' do
      expect(issue_parent1.journals.count).to eq 0
      expect(issue_parent2.journals.count).to eq 0

      expect { post :create, :params => { :issue => { :parent_issue_id => issue_parent1.id, :project_id => project.id, :subject => 'test_journals' } } }.to change(Issue, :count).by(1)
      issue_child = assigns(:issue)

      expect(issue_parent1.journals.count).to eq 1
      expect(issue_parent2.journals.count).to eq 0

      put :update, :params => { :id => issue_child, :issue => { :parent_issue_id => issue_parent2.id } }

      expect(issue_parent1.journals.count).to eq 2
      expect(issue_parent2.journals.count).to eq 1
    end

    it 'show more journal button visible' do
      issue    = issues.first
      journals = FactoryGirl.create_list(:journal, 3, issue: issue, journalized_type: 'Issue')
      with_easy_settings(easy_extensions_journal_history_limit: 2) do
        get :show, params: { id: issue }
      end
      expect(response).to render_template('issues/show')
      expect(assigns[:journals].count).to eq 2
      expect(assigns[:journal_count]).to eq 3
    end

  end

  context 'when update with back_url to specific filter' do
    context 'when back_url param' do
      it 'redirects to specified filter' do
        back_url = "#{issues_url}?set_filter=1&assigned_to_id=%3Dme|28"
        put :update, :params => { :id => issue, :issue => { :subject => "UPDATED" }, :back_url => back_url }

        expect(response.header["Location"]).to eq(Addressable::URI.escape(back_url))
      end
    end

    context 'when back_url2 param' do
      it 'redirects to specified filter' do
        back_url2 = "#{issues_url}?set_filter=1&assigned_to_id=%3Dme|28"
        put :update, :params => { :id => issue, :issue => { :subject => "UPDATED" }, :back_url2 => back_url2 }

        expect(response.header["Location"]).to eq(Addressable::URI.escape(back_url2))
      end
    end
  end

  context 'send external email' do
    before do
      allow_any_instance_of(Issue).to receive(:maintained_by_easy_helpdesk?).and_return(true)
      allow_any_instance_of(Issue).to receive(:easy_email_to).and_return('test@test.com')
    end

    context 'change back url' do
      it 'redirects to preview' do
        put :update, params: { id: issue, issue: { subject: "UPDATED", send_to_external_mails: '1' } }
        back_url = issue_preview_external_email_url(id: issue.id, back_url: issue_path(issue))
        expect(response.header["Location"]).to eq(CGI.unescape(back_url))
      end

      it 'redirects to original_back_url' do
        put :update, params: { id: issue, issue: { subject: "UPDATED", send_to_external_mails: '0' } }
        expect(response.header["Location"]).to eq(Addressable::URI.escape(issue_url(issue)))
      end
    end
  end

  context 'autolinks' do
    render_views

    it 'doesnt autolink messages' do
      with_settings({ 'text_formatting' => 'HTML' }) do
        issue = FactoryGirl.create(:issue)
        issue.update_column(:description, "<p>message:-</p>")
        get :show, :params => { :id => issue.id }
        assert_response :success
      end
    end
  end

  context 'due date by milestone', logged: :admin do
    let(:version) { FactoryBot.create(:version, effective_date: Date.today, sharing: 'system') }
    let(:version_past) { FactoryBot.create(:version, effective_date: Date.today - 1.day, sharing: 'system') }

    it 'to past' do
      version_past
      issue = FactoryBot.create(:issue, fixed_version: version, due_date: version.due_date, start_date: version.due_date)
      expect(issue.due_date).to eq(version.due_date)
      get :new, params: { id: issue.id, issue: { fixed_version_id: version_past.id, due_date: version_past.due_date.to_s } }
      expect(assigns(:issue).due_date).to eq(version_past.due_date)
    end

    it 'to future' do
      version
      issue = FactoryBot.create(:issue, fixed_version: version_past, due_date: version_past.due_date, start_date: version_past.due_date)
      expect(issue.due_date).to eq(version_past.due_date)
      get :new, params: { id: issue.id, issue: { fixed_version_id: version.id, due_date: version_past.due_date.to_s } }
      expect(assigns(:issue).due_date).to eq(version_past.due_date)
    end
  end

  describe '#bulk_update' do
    context 'copy' do
      let(:issue) { FactoryBot.create(:issue, subject: 'Issue1', start_date: '2019-02-02', due_date: '2019-02-06') }

      context 'moving dates' do
        let(:child_issue) { FactoryBot.create(:issue, subject: 'child', parent_id: issue.id, start_date: '2019-02-02', due_date: '2019-02-06') }
        let(:params) do
          {
              ids:           [issue.id, child_issue.id],
              issue:         {
                  start_date_type: 'change_by',
                  start_date:      '7',
                  due_date_type:   'change_by',
                  due_date:        '5'
              },
              link_copy:     '1',
              copy_subtasks: '1',
              copy:          '1'
          }
        end

        it 'moves dates of child issues' do
          with_settings(parent_issue_dates: 'independent') do
            child_issue

            expect { post :bulk_update, params: params }.to change(Issue, :count).by(2)
            # moved by same number of days
            expect(Issue.last(2).pluck(:start_date, :due_date).flatten.uniq).to eq([Date.new(2019, 02, 9), Date.new(2019, 02, 11)])
          end
        end
      end
    end
  end

  describe '#update' do

    context 'assignee validation' do

      it 'invalid assignee' do
        patch :update, params: { id: issue, validate_assignee: true, issue: { assigned_to_id: User.current } }
        expect(response).to have_http_status(422)
      end

      it 'valid assignee', logged: :admin do
        issue = FactoryBot.create(:issue, project: FactoryBot.create(:project, members: [User.current]))
        patch :update, params: { id: issue, validate_assignee: true, issue: { assigned_to_id: User.current }, format: 'json' }
        expect(response).to have_http_status(204)
      end

    end
  end

  describe '#destroy' do
    context 'destroy issue and time entries will return 422' do
      it 'fail when reassigned id is not exists' do
        time_entry

        expect {
          expect {
            delete :destroy, params: { id: issue.id, todo: 'reassign', reassign_to_id: 0, format: :json }
            expect(response).to have_http_status(422)
          }.to_not change{ TimeEntry.count }
        }.to_not change{ Issue.count}
      end

      it 'fails when reassigned id is id of issue which will be deleted' do
        time_entry

        expect {
          expect {
            delete :destroy, params: { id: issue.id, todo: 'reassign', reassign_to_id: issue.id, format: :json }
            expect(response).to have_http_status(422)
          }.to_not change{ TimeEntry.count }
        }.to_not change{ Issue.count }
      end
    end
  end
end
