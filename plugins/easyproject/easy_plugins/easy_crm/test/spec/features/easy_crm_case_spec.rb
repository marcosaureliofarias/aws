require_relative '../spec_helper'

feature 'CRM Cases', :logged => :admin, :js => true do
  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project) }
  let(:easy_crm_case_with_items) { FactoryGirl.create(:easy_crm_case, :with_items) }

  scenario 'show groups if the contacts table is included' do
    easy_crm_case
    visit easy_crm_cases_path(:set_filter => '1', :load_groups_opened => '1', :sort => 'assigned_to,easy_contacts.contact_name', :group_by => [:assigned_to, :easy_crm_case_status], :column_names => ['project', 'easy_contacts.contact_name', 'assigned_to'])
    wait_for_ajax
    expect(page).to have_css('.entities .group', :count => 1)
    expect(page).to have_css(".entities tr#entity-#{easy_crm_case.id}", :count => 1)
  end

  scenario 'show detail with items' do
    with_easy_settings('easy_crm_use_items' => true) do
      visit easy_crm_case_path(easy_crm_case_with_items)
      wait_for_ajax
      expect(page).to have_css('#easy_crm_case_items_container')
    end
  end

  scenario 'edit description' do
    with_settings({'text_formatting' => 'HTML'}) do
      visit edit_easy_crm_case_path(easy_crm_case)
      wait_for_ajax
      page.find('.issue-edit-hidden-attributes').click
      page.find('#description_toggler').click
      wait_for_ajax
      expect(page).to have_css('#cke_easy_crm_case_description')
    end
  end
end
