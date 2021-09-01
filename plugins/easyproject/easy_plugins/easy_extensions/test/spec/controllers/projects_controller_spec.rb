require 'easy_extensions/spec_helper'

describe ProjectsController, :logged => :admin do
  describe 'INDEX' do

    let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking']) }

    context 'projects tree' do
      let!(:child) { FactoryGirl.create(:project, parent: project, name: 'Child project') }

      it 'render parent project of filtered project with nonfilter set' do
        get :index, :params => { set_filter: 1, name: '~child' }
        expect(assigns(:projects).size).to eq(1) # only roots on first request
        expect(assigns(:projects).first.id).to eq(project.id)
        expect(assigns(:projects).first.nofilter).not_to be_blank
      end

      it 'return right children set with root_id set' do
        get :index, :params => { set_filter: 1, name: '~child', root_id: project.id }
        expect(assigns(:projects).size).to eq(1)
        expect(assigns(:projects).first.id).to eq(child.id)
        expect(assigns(:projects).first.nofilter).to be_blank
      end

      it 'return empty set if all projects are filtered' do
        get :index, :params => { set_filter: 1, name: '~deploy' }
        expect(assigns(:projects).size).to eq(0)
      end

    end

    context 'outputs' do
      render_views

      ['list', 'tiles', 'calendar', 'chart', 'report'].each do |output|
        it output do
          get :index, :params => { set_filter: 1, outputs: [output] }
          expect(response).to be_successful
        end
      end
    end

    context 'EXPORTS' do
      render_views

      it 'exports to pdf' do
        get :index, :params => { :format => 'pdf', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/pdf')
      end

      it 'exports to xlsx' do
        get :index, :params => { :format => 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      it 'exports to xlsx aggr' do
        get :index, :params => { :format => 'xlsx', set_filter: '1', aggregated_hours: '1' }
        expect(response).to be_successful
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      it 'exports to csv' do
        get :index, :params => { :format => 'csv', set_filter: '0', easy_query: { columns_to_export: 'all' } }
        expect(response).to be_successful
        expect(response.content_type).to include('text/csv')
      end
    end

    context 'API' do
      render_views

      it 'renders projects to JSON' do
        count = Project.count
        get :index, :params => { :format => 'json' }
        expect(response).to be_successful
        expect(json).to have_key(:projects)
        expect(json[:total_count]).to eq(count)
        expect(json[:projects].count).to eq(count)
      end
    end

    context 'SETTINGS' do
      render_views

      context 'EXPORTS' do
        context 'milestones in project settings' do
          it 'exports to pdf' do
            get :settings, :params => { :id => project.id, :tab => 'versions', :format => 'pdf', set_filter: '0', easy_query: { columns_to_export: 'all' } }
            expect(response).to be_successful
            expect(response.content_type).to eq('application/pdf')
          end

          it 'exports to xlsx' do
            get :settings, :params => { :id => project.id, :tab => 'versions', :format => 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
            expect(response).to be_successful
            expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          end

          it 'exports to csv' do
            get :settings, :params => { :id => project.id, :tab => 'versions', :format => 'csv', set_filter: '0', easy_query: { columns_to_export: 'all' } }
            expect(response).to be_successful
            expect(response.content_type).to include('text/csv')
          end
        end
      end

      context 'per module', :logged => true do
        let!(:member) do
          m          = Member.new(:user_id => User.current.id, :project_id => FactoryGirl.create(:project).id)
          m.role_ids = [Role.create(:name => 'edit_own_projects', :permissions => ['edit_own_projects']).id]
          m.save!
        end

        it 'get projects settings without permissions' do
          Redmine::AccessControl.available_project_modules.each do |project_module|
            project.enabled_module_names = [project_module]
            project.save
            User.current.reload
            get :settings, :params => { :id => project }
            raise "response: #{response.status} #{project_module}" if response.status != 200
          end
        end
      end

      it 'add a comment' do
        expect { put :update_history, :params => { :id => project, :notes => 'test' } }.to change(project.journals, :count).by(1)
      end

      it 'add note to history when #close' do
        expect { post :close, params: { id: project } }.to change(project.journals, :count).by(1)
      end

      it 'add note to history when #reopen' do
        project.update!(status: Project::STATUS_CLOSED)
        expect { post :reopen, params: { id: project } }.to change(project.journals, :count).by(1)
      end

      it 'add note to history when #archive' do
        expect { post :archive, params: { id: project } }.to change(project.journals, :count).by(1)
      end

      it 'add note to history when #unarchive' do
        project.update!(status: Project::STATUS_ARCHIVED)
        expect { post :unarchive, params: { id: project } }.to change(project.journals, :count).by(1)
      end

    end

    context 'queries', skip: !Redmine::Plugin.installed?(:easy_contacts) do
      let!(:project1) { FactoryBot.create(:project) }
      let!(:project2) { FactoryBot.create(:project, parent: project1) }
      let!(:easy_contact) { FactoryBot.create(:easy_contact, projects: [project1]) }

      it 'select projects for contact' do
        expect(easy_contact.projects.count).to eq(1)
        get :index, params: {  type: 'EasyProjectQuery',  source_entity_type: 'EasyContact', source_entity_id: easy_contact.id,
                               referenced_collection_name: 'projects', outputs: ['list'] }
        expect(response).to be_successful
        expect(assigns(:query).entity_count).to eq(1)
        expect(assigns(:query).display_as_tree?).to eq(true)
        expect(assigns(:projects).count).to eq(1)

      end
    end

  end

  describe '#deliver_all_planned_emails' do
    let!(:project) { FactoryBot.create(:project, name: 'Planned', status: Project::STATUS_PLANNED, number_of_issues: 1) }

    before(:each) do
      ActionMailer::Base.deliveries = []
    end

    it 'sends all emails' do
      with_deliveries do
        put :update, params: { format: 'json', id: project.id, project: { send_all_planned_emails: '1', is_planned: false} }
      end
      expect(response).to be_successful
      expect(assigns(:project).status).to eq(Project::STATUS_ACTIVE)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it 'should not send emails' do
      with_deliveries do
        put :update, params: { format: 'json', id: project.id, project: { is_planned: false} }
      end
      expect(response).to be_successful
      expect(assigns(:project).status).to eq(Project::STATUS_ACTIVE)
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end

  describe '#search' do
    let(:project) { FactoryGirl.create(:project, name: 'Vyhledavany projekt') }

    it 'find project matching query' do
      get :index, :params => { easy_query_q: 'Vyhledavany' }
      expect(response).to be_successful
    end
  end

  describe '#copy' do
    context 'project with subprojects and subproject template' do
      let!(:parent_project) { FactoryGirl.create(:project, :with_subprojects, :number_of_subprojects => 2) }
      let!(:template) { FactoryGirl.create(:project, :easy_is_easy_template => true, :parent => parent_project) }
      let(:invalid_query) { FactoryGirl.build(:easy_issue_query,
                                              :project => parent_project,
                                              :filters => { 'tracker_id' => { :values => [(Tracker.last.id + 1).to_s], :operator => '=' } })
      }
      let(:copy_params) {
        {
            "project" => {
                "name"                            => parent_project.name,
                "parent_id"                       => nil,
                "description"                     => parent_project.description,
                "homepage"                        => parent_project.homepage,
                "author_id"                       => User.current.id,
                "is_public"                       => parent_project.is_public,
                "is_planned"                      => parent_project.is_planned,
                "inherit_members"                 => parent_project.inherit_members,
                "easy_is_easy_template"           => parent_project.easy_is_easy_template,
                "inherit_easy_invoicing_settings" => Redmine::Plugin.installed?(:easy_invoicing) ? parent_project.inherit_easy_invoicing_settings : false,
                "inherit_time_entry_activities"   => parent_project.inherit_time_entry_activities,
                "inherit_easy_money_settings"     => Redmine::Plugin.installed?(:easy_money) ? parent_project.inherit_easy_money_settings : false,
                "project_custom_field_ids"        => parent_project.project_custom_fields.pluck(:id),
                "enabled_module_names"            => parent_project.enabled_module_names,
                "tracker_ids"                     => parent_project.trackers.pluck(:id),
                "issue_custom_field_ids"          => parent_project.issue_custom_fields.pluck(:id)
            },
            "only"    => ["easy_page_modules", "subprojects", "members", "versions", "issues", "issue_categories", "easy_queries", "documents", "activity", "news", "easy_contacts", "easy_knowledge", "easy_money", ""],
            "id"      => parent_project.id
        }
      }

      it 'should copy only non-template projects' do
        parent_project.reload

        non_templates_before_copy = 3
        templates_before_copy     = 1

        expect(Project.non_templates.count).to eq(non_templates_before_copy)
        expect(Project.all.count).to eq(non_templates_before_copy + templates_before_copy)

        post :copy, :params => copy_params

        expect(Project.all.count).to eq(templates_before_copy + 2 * non_templates_before_copy)
      end

      it 'should copy with invalid query' do
        allow(invalid_query).to receive(:valid?).and_return(false)

        invalid_query.save(:validate => false)
        expect(invalid_query.valid?).to be false
        parent_project.reload
        expect { post :copy, :params => copy_params }.to change(Project, :count).by(3)
      end
    end

    context 'subproject' do
      let(:project) { FactoryBot.create(:project) }
      let(:target_parent_project) { FactoryBot.create(:project) }

      it 'permissions', logged: true do
        role = Role.non_member
        role.add_permission! :add_subprojects, :copy_project
        role.remove_permission! :add_project, :create_subproject_from_template

        copy_params = {
            "project" => {
                "name"                            => project.name,
                "parent_id"                       => target_parent_project.id
            },
            "id"      => project.id
        }

        expect { post :copy, params: copy_params }.to change(Project, :count).by(1)
        expect(target_parent_project.reload.children.count).to eq(1)
      end
    end
  end

  context 'load allowed parents', :logged => :admin do
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project2) { FactoryGirl.create(:project) }
    let!(:template) { FactoryGirl.create(:project, :easy_is_easy_template => true) }

    render_views

    it 'force templates' do
      get :load_allowed_parents, :params => { :id => project.id, :format => :json, :force => 'templates' }
      expect(response).to be_successful
      expect(response.body).to include(template.name)
      expect(response.body).not_to include(project.name)
      expect(response.body).not_to include(project2.name)
    end

    it 'force projects' do
      get :load_allowed_parents, :params => { :id => project.id, :format => :json, :force => 'projects' }
      expect(response).to be_successful
      expect(response.body).not_to include(template.name)
      expect(response.body).not_to include(project.name)
      expect(response.body).to include(project2.name)
    end
  end

  context 'bulk update', :logged => :admin do
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project2) { FactoryGirl.create(:project) }

    render_views

    it 'destroy' do
      delete :bulk_destroy, :params => { :data => { :ids => [project.id] }}
      expect(response).to render_template(:destroy)
    end

    it 'archive / unarchive' do
      post :bulk_archive, :params => { :data => { :ids => [project.id, project2.id] } }
      [project, project2].each(&:reload)
      expect(project.archived? && project2.archived?).to eq(true)

      post :bulk_unarchive, :params => { :data => { :ids => [project.id, project2.id] } }
      [project, project2].each(&:reload)
      expect(project.archived? || project2.archived?).to eq(false)
    end

    it 'close / reopen' do
      post :bulk_close, :params => { :data => { :ids => [project.id, project2.id] } }
      [project, project2].each(&:reload)
      expect(project.closed? && project2.closed?).to eq(true)

      post :bulk_reopen, :params => { :data => { :ids => [project.id, project2.id] } }
      [project, project2].each(&:reload)
      expect(project.closed? || project2.closed?).to eq(false)
    end
  end

  context 'update', logged: :admin do
    let!(:project) { FactoryGirl.create(:project) }

    context 'API' do
      it 'archive / unarchive' do
        post :archive, params: { format: :json, id: project.id }
        project.reload
        expect(project.archived?).to eq(true)

        post :unarchive, params: { format: :json, id: project.id }
        project.reload
        expect(project.archived?).to eq(false)
      end

      it 'archive skips validation' do
        allow_any_instance_of(Project).to receive(:valid?).and_return(false)
        post :archive, params: { format: :json, id: project.id }
        project.reload
        expect(project.archived?).to eq(true)
        expect(response).to be_successful
      end

      it 'close / reopen' do
        post :close, params: { format: :json, id: project.id }
        project.reload
        expect(project.closed?).to eq(true)

        post :reopen, params: { format: :json, id: project.id }
        project.reload
        expect(project.closed?).to eq(false)
      end
    end
  end

  context 'destroy', logged: :admin do
    let(:project) { FactoryBot.create(:project) }

    it 'should not destroy if confirmation not matched to project name' do
      delete :destroy, params: { id: project.id, confirm: '1', confirm_project_name: 'wrong name' }, format: :html
      expect(project.destroyed?).to be_falsey
      project.reload
      expect(project.archived?).to be_falsey
      expect(project.scheduled_for_destroy?).to be_falsey
    end

    it 'should schedule it for destroy if confirmation matched to project name' do
      delete :destroy, params: { id: project.id, confirm: '1', confirm_project_name: project.name }, format: :html
      expect(project.destroyed?).to be_falsey
      project.reload
      expect(project.archived?).to be_truthy
      expect(project.scheduled_for_destroy?).to be_truthy
    end

    it 'should unschedule the destroying when unarchived' do
      delete :destroy, params: { id: project.id, confirm: '1', confirm_project_name: project.name }, format: :html
      put :unarchive, params: { id: project.id }
      expect(project.scheduled_for_destroy?).to be_falsey
    end

    context 'warning' do
      let(:project_not_to_be_destroyed) { FactoryBot.create(:project) }
      let(:project_to_be_destroyed) { FactoryBot.create(:project, destroy_at: Date.tomorrow) }

      render_views

      it 'shows warning when scheduled for destroy' do
        get :show, params: { id: project_to_be_destroyed.id, format: :html }
        expect(response.body).to include(I18n.t(:warning_project_scheduled_for_destroy))
      end

      it 'doesn\'t show warning when not scheduled for destroy' do
        get :show, params: { id: project_not_to_be_destroyed.id, format: :html }
        expect(response.body).not_to include(I18n.t(:warning_project_scheduled_for_destroy))
      end
    end
  end

  context 'bulk modules' do
    let(:project1) { FactoryBot.create(:project, enabled_module_names: ['issue_tracking']) }
    let(:project2) { FactoryBot.create(:project, enabled_module_names: ['news']) }

    context 'as admin' do
      it 'add modules' do
        expect(project1.enabled_module_names).to eq(['issue_tracking'])
        expect(project2.enabled_module_names).to eq(['news'])

        post :bulk_modules, params: {ids: [project1.id, project2.id], method: 'enable_module', module_names: ['easy_contacts', 'easy_crm']}

        project1.reload
        project2.reload
        expect(project1.enabled_module_names).to include('issue_tracking', 'easy_contacts', 'easy_crm')
        expect(project2.enabled_module_names).to include('news', 'easy_contacts', 'easy_crm')
      end

      it 'deactivate modules' do
        expect(project1.enabled_module_names).to eq(['issue_tracking'])
        expect(project2.enabled_module_names).to eq(['news'])

        post :bulk_modules, params: {ids: [project1.id, project2.id], method: 'disable_module', module_names: ['news']}

        project1.reload
        project2.reload
        expect(project1.enabled_module_names).to eq(['issue_tracking'])
        expect(project2.enabled_module_names).to eq([])
      end

      it 'overwrite modules' do
        expect(project1.enabled_module_names).to eq(['issue_tracking'])
        expect(project2.enabled_module_names).to eq(['news'])

        post :bulk_modules, params: {ids: [project1.id, project2.id], method: 'overwrite', module_names: ['easy_contacts', 'easy_crm']}

        project1.reload
        project2.reload
        expect(project1.enabled_module_names).to include('easy_contacts', 'easy_crm')
        expect(project2.enabled_module_names).to include('easy_contacts', 'easy_crm')
      end
    end

    context 'permissions', logged: true do
      let(:role) { FactoryBot.create(:role, permissions: [:view_projects, :edit_project, :select_project_modules]) }
      let(:member) { FactoryBot.create(:member, roles: [role], project: project1, user: User.current) }

      it 'dont change projects without perm' do
        project1.members << member

        expect(project1.enabled_module_names).to eq(['issue_tracking'])
        expect(project2.enabled_module_names).to eq(['news'])

        post :bulk_modules, params: {ids: [project1.id, project2.id], method: 'enable_module', module_names: ['easy_contacts', 'easy_crm']}

        project1.reload
        project2.reload
        expect(project1.enabled_module_names).to include('issue_tracking', 'easy_contacts', 'easy_crm')
        expect(project2.enabled_module_names).to eq(['news'])
      end
    end
  end
end
