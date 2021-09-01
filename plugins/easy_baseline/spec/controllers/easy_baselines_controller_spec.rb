require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

describe EasyBaselinesController, :logged => :admin do
  let(:project) { FactoryBot.create(:project, :add_modules => %w(easy_baselines easy_gantt)) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      example.run
    end
  end

  describe '#new' do
    it 'accept name param' do
      get :new, params: {project_id: project, easy_baseline: { name: 'Specialni jmeno' }}
      expect(assigns(:baseline).name).to eq('Specialni jmeno')
    end

    it 'baselines project' do
      project
      expect{
        get :new, params: {project_id: project, easy_baseline: { name: 'Specialni jmeno' }}
      }.to change(Project, :count).by(1)
    end

    it 'baselines project with identifiers enabled' do
      project
      with_easy_settings(:project_display_identifiers => true) do
        expect{
          get :new, params: {project_id: project, easy_baseline: { name: 'Specialni jmeno' }}
        }.to change(Project, :count).by(1)
      end
    end
  end

  describe '#create' do
    it 'accept name param and create baseline' do
      expect {
        post :create, params: { project_id: project, easy_baseline: { name: 'Specialni jmeno' } }
      }.to have_enqueued_job(CreateEasyBaselineJob)
    end

    it 'try to create without name' do
      expect {
        post :create, params: { project_id: project, easy_baseline: {} }
      }.to have_enqueued_job(CreateEasyBaselineJob)
    end

    it 'try to create without easy_baseline' do
      expect {
        post :create, params: { project_id: project }
      }.to have_enqueued_job(CreateEasyBaselineJob)
    end
  end
end
