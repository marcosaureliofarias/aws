require_relative '../spec_helper'

feature 'CRM case items', :logged => :admin, :js => true, :js_wait => :long do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project) }

  scenario 'recalculate total price' do
    with_easy_settings(:easy_crm_use_items => true) do
      visit easy_crm_case_path(easy_crm_case)
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      page.find("a[title='#{I18n.t(:button_easy_crm_add_item)}']").click
      wait_for_ajax
      page.find('#easy_crm_case_items_container a.add_fields').click unless Redmine::Plugin.installed?(:easy_price_books)
      page.find('#easy_crm_case_items_container input[id$=_amount]').set(2)
      page.find('#easy_crm_case_items_container input[id$=_price_per_unit]').set(5)
      total_price = page.find('#easy_crm_case_items_container input[id$=_total_price]')
      total_price.click
      expect(total_price.value).to eq('10.00')
    end
  end
end
