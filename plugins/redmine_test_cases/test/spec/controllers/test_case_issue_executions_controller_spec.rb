require 'easy_extensions/spec_helper'

describe TestCaseIssueExecutionsController, logged: :admin do
  let(:project) { FactoryBot.create(:project, :add_modules => %w(test_cases)) }
  let(:test_case) { FactoryBot.create(:test_case, :with_issues, project_id: project.id) }
  let(:test_case_issue_execution) { FactoryBot.create(:test_case_issue_execution, test_case: test_case) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      example.run
    end
  end

  describe 'basics' do

    render_views
    it 'index' do
      FactoryBot.create_list(:test_case_issue_execution, 5, test_case: test_case)
      get :index, params: {project_id: project}
      expect(response).to be_successful
    end

    it 'new' do
      get :new, params: {test_case_id: test_case.id}
      expect(response).to be_successful
    end

    it 'create' do
      post :create, params: {test_case_id: test_case.id, test_case_issue_execution: FactoryBot.attributes_for(:test_case_issue_execution, issue_id: test_case.issue_ids.first)}
      expect(assigns(:test_case_issue_execution).errors).to be_blank
      expect(response).to redirect_to(assigns(:test_case_issue_execution))
    end

    it 'destroy' do
      expect(test_case_issue_execution.class.count).to eq(1) # touch
      expect{
        delete :destroy, params: {id: test_case_issue_execution.id}
      }.to change(TestCaseIssueExecution, :count).by(-1)
      expect(response).to redirect_to(test_case_issue_executions_path(project_id: assigns(:project)))
    end

    context 'api' do
      it 'index' do
        test_case_issue_execution
        get :index, params: {format: 'json'}
        expect(response).to be_successful
      end

      it 'show' do
        get :show, params: {format: 'json', id: test_case_issue_execution.id }
        expect(response).to be_successful
      end
    end

  end

end
