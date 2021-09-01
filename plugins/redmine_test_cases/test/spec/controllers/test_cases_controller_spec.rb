require 'easy_extensions/spec_helper'

describe TestCasesController, logged: :admin do
  let(:project) { FactoryBot.create(:project, :add_modules => %w(test_cases)) }
  let(:test_case) { FactoryBot.create(:test_case, project_id: project.id) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      example.run
    end
  end

  describe 'basics' do

    render_views
    it 'index' do
      _test_cases = FactoryBot.create_list(:test_case, 5, project: project)
      get :index, params: {project_id: project}
      expect(response).to be_successful
      expect(response.body).to include('New test plan')
    end

    it 'new' do
      get :new
      expect(response).to be_successful
    end

    it 'create' do
      post :create, params: {test_case: FactoryBot.attributes_for(:test_case, project_id: project.id, author_id: User.current.id)}
      expect(assigns(:test_case).errors).to be_blank
      expect(response).to redirect_to(test_case_path(assigns(:test_case)))
    end

    it 'destroy' do
      expect(test_case.class.count).to eq(1) # touch
      expect{
        delete :destroy, params: {id: test_case.id}
      }.to change(TestCase, :count).by(-1)
      expect(response).to redirect_to(test_cases_path(project_id: test_case.project_id))
    end

  end

  context 'api' do
    it 'index' do
      test_case
      get :index, params: {format: 'json'}
      expect(response).to be_successful
    end

    it 'show' do
      get :show, params: {format: 'json', id: test_case.id }
      expect(response).to be_successful
    end
  end

end
