require_relative '../spec_helper'

feature 'CRM Entity Assignments', :logged => :admin, :js => true, :js_wait => :long do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project) }

  scenario 'assign issue' do
    visit easy_crm_case_path(easy_crm_case)
    wait_for_ajax
    page.find(".menu-more-container .menu-expander").click
    page.find(".menu-more-sidebar a[title='#{I18n.t(:button_easy_crm_add_or_create_related_issue)}']").click
    wait_for_ajax
    page.find("#ajax-modal .issues .issue .buttons > a[title='#{I18n.t(:button_easy_crm_add_related_issue)}']").click
    wait_for_ajax
    expect(page).to have_css("#entity_easy_crm_case_#{easy_crm_case.id}_issues_container")
  end
end
