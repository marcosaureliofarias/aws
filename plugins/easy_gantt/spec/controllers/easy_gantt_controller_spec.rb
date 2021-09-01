require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.describe EasyGanttController, logged: :admin do

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  context 'rest api' do
    let(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt']) }

    it 'disabled' do
      with_settings(rest_api_enabled: 0) do
        get :index, params: { project_id: project }
        expect(response).to be_server_error

        get :index
        expect(response).to be_server_error
      end
    end

    it 'enabled' do
      get :index
      expect(response).to be_successful
    end

    it 'ignores sorting array' do
      with_easy_settings(easy_gantt_easy_issue_query_default_sorting_array: [['project', 'asc']]) do
        get :issues, params: { project_id: project.id, format: 'json' }
        expect(response).to be_successful
      end
    end

    it 'project gantt build dates' do
      effective_date = Date.today + 6.months # from factory :version
      project = FactoryGirl.create(:project, :with_milestones, add_modules: ['easy_gantt'])
      project_start_date = Date.today - 5.days
      project_end_date = Date.today + 5.days

      allow(Project).to receive(:find).with(project.id.to_s).and_return(project)
      allow(project).to receive(:gantt_start_date).and_return(project_start_date)
      allow(project).to receive(:gantt_due_date).and_return(project_end_date)

      with_easy_settings(easy_gantt_show_holidays: true) do
        get :issues, params: { project_id: project.id, format: 'json' }
        expect(assigns[:start_date]).to eq(project_start_date - 1.days)
        expect(assigns[:end_date]).to eq(effective_date + 1.days)
      end
    end
  end

end
