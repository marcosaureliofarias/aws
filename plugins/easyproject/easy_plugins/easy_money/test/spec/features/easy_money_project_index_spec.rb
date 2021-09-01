require 'easy_extensions/spec_helper'

feature 'Project index', logged: :admin, js: true do

  let(:project) { FactoryGirl.create(:project, enabled_module_names: ['easy_money'])}
  let(:subproject) { FactoryGirl.create(:project, parent_id: project.id)}
  let(:subsubproject) { FactoryGirl.create(:project, parent_id: subproject.id, enabled_module_names: ['easy_money'])}

  scenario 'display child without money' do
    subsubproject
    visit "projects/#{project.id}/easy_money"
    expect(page).to have_css('table#easy-money-subproject td.project-name', text: subproject.name)
    expect(page).not_to have_css('table#easy-money-subproject td.project-name a', text: subproject.name)
  end

end
