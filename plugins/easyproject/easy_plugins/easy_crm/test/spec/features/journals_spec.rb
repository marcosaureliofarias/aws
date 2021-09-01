require_relative '../spec_helper'

feature 'CRM Journals', :logged => :admin, :js => true, :js_wait => :long do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project) }

  scenario 'change attribute' do
    visit easy_crm_case_path(easy_crm_case)
    expect(page).not_to have_selector('#history .journal')
    visit edit_easy_crm_case_path(easy_crm_case)
    wait_for_ajax
    cancelled = page.find("#easy_crm_case_is_canceled")
    expect(cancelled).not_to be_checked
    cancelled.set(true)
    page.find("input[type='submit']").click
    # page.find('#journal_important_items_help > a').click
    expect(page).to have_selector('.journal', count: 1)
  end

  scenario 'add note' do
    # with_settings({'text_formatting' => 'HTML'}) do
      visit easy_crm_case_path(easy_crm_case)
      expect(page).not_to have_selector('.journal')
      visit edit_easy_crm_case_path(easy_crm_case)
      wait_for_ajax
      sleep 1
      text = 'test note'
      # fill_in_ckeditor(1, :context => '#easy_crm_case_form', :with => text)
      page.find('#easy_crm_case_notes').set(text)
      page.find("input[type='submit']").click
      expect(page).to have_selector('.journal', count: 1)
      expect(page.find('.journal')).to have_text(text)
    # end
  end
end
