require_relative '../spec_helper'

feature 'entity cards', :logged => :admin, :js => true do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let!(:easy_contact) { FactoryGirl.create(:account_easy_contact) }
  let!(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project, :easy_contacts => [easy_contact]) }

  scenario 'related contact on crm case' do
    visit easy_crm_case_path(easy_crm_case)
    wait_for_ajax
    container_id = "#entity_easy_crm_case_#{easy_crm_case.id}_easy_contacts_container"
    expect(page).to have_css(container_id)
    container = page.find(container_id)
    container.click
    expect(container).to have_text(easy_contact.name)
  end

  scenario 'related crm case on contact' do
    visit easy_contact_path(easy_contact)
    wait_for_ajax
    container_id = "#entity_easy_contact_#{easy_contact.id}_easy_crm_cases_container"
    expect(page).to have_css(container_id)
    container = page.find(container_id)
    container.click
    expect(container).to have_text(easy_crm_case.name)
  end
end
