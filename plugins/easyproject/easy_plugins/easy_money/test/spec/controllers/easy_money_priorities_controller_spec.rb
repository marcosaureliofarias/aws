require 'easy_extensions/spec_helper'

describe EasyMoneyPrioritiesController, logged: :admin do

  let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_money']) }
  let(:project_rate_priority_1) { FactoryBot.create(:easy_money_rate_priority, project: project, entity_type: 'User', position: 1, rate_type_id: 1) }

  let(:sub_project) { FactoryBot.create(:project, parent: project, enabled_module_names: ['easy_money']) }
  let(:sub_project_rate_priority_1) { FactoryBot.create(:easy_money_rate_priority, project: sub_project, entity_type: 'User', position: 0, rate_type_id: 1) }

  it '#update_priorities_to_subprojects' do
    project_rate_priority_1
    sub_project_rate_priority_1
    get :update_priorities_to_subprojects, params: { project_id: project.id }
    sub_project_rate_priority_1.reload
    expect(sub_project_rate_priority_1.position).to eq(project_rate_priority_1.position)
  end
end
