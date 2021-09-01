require_relative '../spec_helper'

feature 'easy page', :logged => :admin, :js => true, :js_wait => :long do
  let(:project) { FactoryGirl.create(:project) }

  context 'add module' do

    scenario 'generic gauge with sumable column out of query' do
      visit url_for({:controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true})
      select_easy_page_module(I18n.t(:generic_gauge, scope: [:easy_pages, :modules]), 'top')
      gauge_name = page.first('input[id^="generic_gauge_"]')
      gauge_type = page.first('select[id^="generic_gauge_"]')
      gauge_name.set('hi')
      gauge_type.find('[value=easy_invoice_query]').select_option
      wait_for_ajax
      gauge_sumable_column = page.find('select[id$="_sumable_column"]')
      gauge_sumable_column.find('[value=easy_crm_cases\.price]').select_option
      wait_for_ajax
      #page.find('h3', :text => I18n.t(:'easy_page_module.generic_gauge.label_quick_tag', :tag_no => 1)).click
      gauge_filter_name = page.find('input[id$="_tags_0_name"]')
      gauge_filter_plan = page.find('input[id$="_tags_0_plan"]')
      gauge_filter = page.find('select[id$="_0add_filter_select"]')
      gauge_filter_name.set('gauge filter tag no 1')
      gauge_filter_plan.set('1000')
      gauge_filter.find('[value=easy_crm_cases\.assigned_to_id]').select_option
      wait_for_ajax
      save_easy_page_modules
      expect( page ).to have_content('gauge filter tag no 1')
    end if Redmine::Plugin.installed?(:easy_invoicing)

  end

  context 'redirection test' do

    scenario 'easy crm adding module and inline edit' do
      visit easy_crm_path
      page.find('.customize-button').click
      wait_for_ajax
      select_easy_page_module(I18n.t(:issue_query, scope: [:easy_pages, :modules]), 'top')
      save_easy_page_modules
      wait_for_ajax

      expect(page).to have_css('.module-heading-links .icon-edit')
      expect(page.current_path).to eq easy_crm_path

      page.find('.module-heading-links .icon-edit').click
      wait_for_ajax
      page.find('input[id$=output_chart]').click
      wait_for_ajax
      page.find('.ui-dialog-buttonset button.button-positive').click

      expect(page).to have_css('.module-heading-links .icon-edit')
      expect(page.current_path).to eq easy_crm_path
    end

    scenario 'easy crm after tab change' do
      visit easy_crm_path
      page.find('.customize-button').click
      wait_for_ajax
      page.find('.add-tab-button').click
      wait_for_ajax
      page.find('.add-tab-button').click
      wait_for_ajax
      save_easy_page_modules
      wait_for_ajax
      page.find('.customize-button').click
      wait_for_ajax
      page.find('#tab_1').click
      wait_for_ajax
      save_easy_page_modules
      wait_for_ajax

      expect(page).to have_css('.customize-button')
      uri = URI.parse(current_url)
      url = [uri.path, uri.query].join('?')
      expect(url).to eq easy_crm_path(t: 1)
    end

  end

end
