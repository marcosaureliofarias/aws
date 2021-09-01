require 'easy_extensions/spec_helper'
describe IssuesController, logged: :true do

  context '#authorize_subordinate' do
    
    before :each do
      allow(User).to receive(:current).and_return(current_user)
      # by default factory role created with all the permissions
    end

    let(:subordinate) { FactoryGirl.create(:user) }
    let!(:current_user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [subordinate]) }
    let!(:my_project) { FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [current_user]) }
    let!(:my_issue) { FactoryBot.create(:issue, project: my_project, assigned_to: current_user) }
    let!(:subordinates_issue) { FactoryBot.create(:issue, author: subordinate, project: project) }

    it 'forbidden' do
      EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => subordinate.to_gid_param}}})
      
      with_easy_settings('easy_org_chart_share_subordinates_access' => 'forbidden') do
        # should be authorized own issues
        get :show, params: { id: my_issue.id, format: 'html' }
        expect(response).to have_http_status(:success)

        # access_denied according forbidden permissions
        get :show, params: { id: subordinates_issue.id, format: 'html' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'shared direct subordinate\'s access' do
      EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => subordinate.to_gid_param}}})
      
      with_easy_settings('easy_org_chart_share_subordinates_access' => 'direct_subordinates') do
        # should be authorized own issues
        get :show, params: { id: my_issue.id, format: 'html' }
        expect(response).to have_http_status(:success)

        # shared access according direct_subordinates permissions
        get :show, params: { id: subordinates_issue.id, format: 'html' }
        expect(response).to have_http_status(:success)
      end
    end

    it 'shared subordinate\'s tree access' do
      user1 = FactoryBot.create(:user)
        project1 = FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [user1])

        subordinates_issue1 = FactoryBot.create(:issue, assigned_to: user1, project: project1)
        tree = {'id' => subordinate.to_gid_param, 'children' => {'1' => {'id' => user1.to_gid_param}}}
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => tree}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'subordinates_tree') do
          # should be authorized own issues
          get :show, params: { id: my_issue.id, format: 'html' }
          expect(response).to have_http_status(:success)

          # shared access according subordinates_tree permissions
          get :show, params: { id: subordinates_issue.id, format: 'html' }
          expect(response).to have_http_status(:success)

          get :show, params: { id: subordinates_issue1.id, format: 'html' }
          expect(response).to have_http_status(:success)
        end
    end
  end
end
