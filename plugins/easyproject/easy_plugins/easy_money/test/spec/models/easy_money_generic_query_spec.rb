require 'easy_extensions/spec_helper'

describe EasyMoneyGenericQuery do
  let!(:project_with_subproject) { FactoryGirl.create(:project, status: Project::STATUS_PLANNED, enabled_module_names: ['easy_money']) }
  let!(:subproject) { FactoryGirl.create(:project, parent: project_with_subproject, status: Project::STATUS_PLANNED, enabled_module_names: ['easy_money']) }

  it 'include planned' do
    q = EasyMoneyGenericQuery.new
    q.project = project_with_subproject.reload
    allow(project_with_subproject.easy_money_settings).to receive(:include_childs?).and_return(true)

    pst = q.project_statement
    expect(pst).to include(project_with_subproject.id.to_s)
    expect(pst).to include(subproject.id.to_s)
  end
end