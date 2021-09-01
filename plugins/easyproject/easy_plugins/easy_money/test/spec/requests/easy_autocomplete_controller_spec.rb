require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, type: :request do
  include_context 'logged as admin'

  let(:issue) { FactoryBot.create(:issue) }
  let(:project1) { FactoryBot.create(:project, issues: [issue], number_of_issues: 0) }
  let(:project2) { FactoryBot.create(:project, number_of_issues: 1) }

  it 'project_entities' do
    project2
    get '/easy_autocompletes/project_entities', params: {format: 'json', project_id: project1.id, entity_type: 'Issue'}
    expect(response).to have_http_status(:success)
    expect(body).to include(issue.subject)
    expect(body).not_to include(project2.issues.first.subject)
  end

end