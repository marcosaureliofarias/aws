require 'easy_extensions/spec_helper'

feature 'easy helpdesk projects', js: true, logged: :admin do

  let(:easy_helpdesk_project) { FactoryBot.create(:easy_helpdesk_project) }
  let(:project) { FactoryBot.create(:project) }

  it 'sla settings' do
    visit edit_easy_helpdesk_project_path(easy_helpdesk_project)
    sla = page.find('.easy-helpdesk-project-sla')
    add_sla = sla.find('a.add_fields')
    2.times { add_sla.click }
    expect(sla).to have_selector('.nested-fields', :count => 2)
    expect(sla).to have_selector('.icon-reorder', :count => 2)
    sla.all('.expander').each { |e| e.click }
    expect(sla).to have_selector('a.remove_fields', :count => 2)
    sla.all('a.remove_fields').each { |e| e.click }
    expect(sla).not_to have_selector('a.remove_fields', :count => 2)
  end
  
  it 'new hd project' do
    visit new_easy_helpdesk_project_path(easy_helpdesk_project: {project_id: project, easy_helpdesk_project_matching_attributes: [{domain_name: 'xxx'}]})
    wait_for_ajax
    page.find(".form-actions input[type='submit']").click
    wait_for_ajax
    expect(page).to have_css('.easy-entity-list')
  end
end
