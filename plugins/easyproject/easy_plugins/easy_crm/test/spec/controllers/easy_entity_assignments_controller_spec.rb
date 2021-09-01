require_relative '../spec_helper'

describe EasyEntityAssignmentsController, logged: :admin do
  let(:project) { FactoryBot.create(:project, add_modules: ['easy_crm', 'issue_tracking']) }
  let(:project2) { FactoryBot.create(:project, add_modules: ['easy_crm', 'issue_tracking']) }
  let(:easy_crm_case) { FactoryBot.create(:easy_crm_case, project: project) }
  let(:issue) { FactoryBot.create(:issue, project: easy_crm_case.project) }
  let(:issue2) { FactoryBot.create(:issue, project: project2) }
  let(:issue3) { FactoryBot.create(:issue, project: project2) }

  it 'cross project' do
    easy_crm_case.issues = [issue, issue2]
    expect(easy_crm_case.issues.count).to eq(2)
    get :index, params: { project_id: easy_crm_case.project_id, set_filter: 1, type: 'EasyIssueQuery', source_entity_type: 'EasyCrmCase', source_entity_id: easy_crm_case.id,
      referenced_collection_name: 'issues', output: 'tiles' }
    expect(response).to be_successful
    expect(assigns(:easy_query).entity_count).to eq(2)
  end

  context 'sort' do
    let(:issue) { FactoryBot.create(:issue, project: easy_crm_case.project, subject: 'BBB') }
    let(:issue2) { FactoryBot.create(:issue, project: easy_crm_case.project, subject: 'CCC') }
    let(:issue3) { FactoryBot.create(:issue, project: easy_crm_case.project, subject: 'AAA') }

    it 'uses global settings' do
      easy_crm_case.issues = [issue, issue2, issue3]
      with_easy_settings('easy_issue_query_default_sorting_array' => [['subject', 'desc']]) do
        get :index, params: { project_id: easy_crm_case.project_id, set_filter: 1, type: 'EasyIssueQuery', source_entity_type: 'EasyCrmCase', source_entity_id: easy_crm_case.id,
          referenced_collection_name: 'issues', output: 'list' }
      end
      expect(response).to be_successful
      expect(assigns(:easy_query).entities.map(&:subject)).to eq([issue2, issue, issue3].map(&:subject))
    end
  end

end
