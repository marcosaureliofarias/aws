require 'easy_extensions/spec_helper'

describe TestPlansController, logged: :admin do
  let(:project) { FactoryBot.create(:project, :add_modules => %w(test_cases)) }
  let(:test_plan) { FactoryBot.create(:test_plan, project_id: project.id) }

  describe 'basics' do

    render_views
    it 'index' do
      _test_plans = FactoryBot.create_list(:test_plan, 3, project: project)
      get :index, params: {project_id: project}
      expect(response).to be_successful
      expect(response.body).to include("Test plan 1")
    end

    it 'new' do
      get :new
      expect(response).to be_successful
    end

    it 'create' do
      post :create, params: {project_id: project.id, test_plan: FactoryBot.attributes_for(:test_plan, project_id: project.id, author_id: User.current.id)}
      expect(assigns(:test_plan).errors).to be_blank
      expect(response).to redirect_to(project_test_plan_path(project, assigns(:test_plan)))
    end

    it 'destroy' do
      expect(test_plan.class.count).to eq(1) # touch
      expect{
        delete :destroy, params: {id: test_plan.id}
      }.to change(TestPlan, :count).by(-1)
      expect(response).to redirect_to(project_test_plans_path(project_id: test_plan.project_id))
    end

  end

end
