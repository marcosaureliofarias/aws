require 'easy_extensions/spec_helper'

describe 'easy_query_settings', logged: :admin, js: true do

  context 'save settings', :slow => true do
    scenario 'save default settings' do
      EasyQuery.registered_subclasses.each_key do |easy_query|
        easy_query_name = easy_query.underscore

        visit "/easy_query_settings/setting?tab=#{easy_query_name}"
        wait_for_ajax
        expect(page).to have_selector(".tabs #tab-#{easy_query_name}.selected", :visible => false)
        page.find('input[type=submit]').click
        wait_for_ajax
        expect(page).to have_selector(".tabs #tab-#{easy_query_name}.selected", :visible => false)

        flash_notice    = page.find('.flash.notice').text
        expected_notice = I18n.t(:notice_successful_update)
        unless flash_notice.include?(expected_notice)
          raise "expected to find '#{expected_notice}' in '#{flash_notice}' - #{easy_query_name}"
        end
      end
    end
  end

  scenario 'remember filters' do
    original = (EasySetting.value(:easy_issue_query_default_filters) || {}).dup
    begin
      visit '/easy_query_settings/setting?tab=easy_issue_query'
      page.find("#easy_issue_query_add_filter_select option[value='project_id']").select_option
      page.find('input[type=submit]').click
      expect(page).to have_css('input#easy_issue_query_cb_project_id')
    ensure
      if setting = EasySetting.where(:name => 'easy_issue_query_default_filters').first
        setting.value = original
        setting.save
      end
    end
  end

  scenario 'hide columns on query edit' do
    visit '/easy_queries/new?type=EasyIssueQuery'
    checkbox = page.find('input#default_columns')
    expect(checkbox).to be_checked
    expect(page).not_to have_css('#columns')
    checkbox.set(false)
    expect(page).to have_css('#columns')

    visit '/easy_queries/new?type=EasyIssueQuery&[column_names][]=project'
    checkbox = page.find('input#default_columns')
    expect(checkbox).not_to be_checked
    expect(page).to have_css('#columns')
    checkbox.set(true)
    expect(checkbox).to be_checked
  end

  context 'default filters' do
    let(:project) { FactoryGirl.create(:project) }

    scenario 'apply a filter which isnt present' do
      with_easy_settings(:easy_issue_query_default_filters => { :project_id => { :operator => '=', :values => ['mine'] } }) do
        visit issues_path(:project_id => project)
        expect(page).to have_css('#easy-query-toggle-button-filters')
      end
    end
  end

end
