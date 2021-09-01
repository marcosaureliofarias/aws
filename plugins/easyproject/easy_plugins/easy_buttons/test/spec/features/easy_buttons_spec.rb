#require 'easy_extensions/spec_helper'
#feature 'easy buttons', :js => true, :js_wait => :long, :logged => :admin do
#
#  let(:issue_status) { FactoryGirl.create(:issue_status) }
#  let(:issue_status2) { FactoryGirl.create(:issue_status) }
#  let(:issue) { FactoryGirl.create(:issue, :assigned_to_id => User.current.id, :status_id => issue_status2.id) }
#  let(:different_user) { FactoryGirl.create(:admin_user) }
#
#  after(:each) do |example|
#    EasyButton.all.each{|b| b.safe_destroy; b.reload_button}
#  end
#
#  scenario 'create and apply an action button' do
#    with_easy_settings(:skip_workflow_for_admin => true) do
#      issue_status
#      visit new_easy_button_path
#      wait_for_ajax
#      page.find('#easy_button_entity_type option[value=\'Issue\']').select_option
#      wait_for_ajax
#      page.fill_in('easy_button_name', :with => 'test button')
#      page.first('#conditionsadd_filter_select option[value=\'assigned_to_id\']').select_option
#      wait_for_ajax
#      expect(page).to have_css('#conditionseasyquery-filters input[value=\'me\']', :visible => false)
#      page.find('#actionsadd_filter_select option[value=\'status_id\']').select_option
#      wait_for_ajax
#      page.find('#actionsdiv_values_status_id button').click
#      page.find('li', text: issue_status.name).click
#      page.find("input[type='submit']").click
#
#      visit(issue_path(issue))
#      wait_for_ajax
#      expect(page.find('#issue-detail-attributes')).to have_content(issue_status2.name)
#      expect(page).to have_css('.easy-action-button', :count => 1)
#      page.find('.easy-action-button').click
#      wait_for_ajax
#      expect(page.find('#issue-detail-attributes')).to have_content(issue_status.name)
#    end
#  end
#
#  scenario 'cache invalidation' do
#    with_easy_settings(:skip_workflow_for_admin => true) do
#      issue_status
#      visit new_easy_button_path
#      wait_for_ajax
#      page.find('#easy_button_entity_type option[value=\'Issue\']').select_option
#      wait_for_ajax
#      page.fill_in('easy_button_name', :with => 'test private button')
#      page.find('#easy_button_is_private').set(true)
#      page.first('#conditionsadd_filter_select option[value=\'assigned_to_id\']').select_option
#      wait_for_ajax
#      expect(page).to have_css('#conditionseasyquery-filters input[value=\'me\']', :visible => false)
#      page.find('#actionsadd_filter_select option[value=\'status_id\']').select_option
#      wait_for_ajax
#      page.find('#actionsdiv_values_status_id button').click
#      page.find('li', text: issue_status.name).click
#      page.find("input[type='submit']").click
#
#      visit(issue_path(issue))
#      wait_for_ajax
#      expect(page).to have_css('.easy-action-button', :count => 1)
#
#      current_user = User.current
#      issue.assigned_to = different_user
#      issue.save
#
#      logged_user(different_user)
#      visit(issue_path(issue))
#      wait_for_ajax
#      expect(page).to have_css('.easy-action-button', :count => 0)
#
#      logged_user(current_user)
#      visit edit_easy_button_path(EasyButton.last)
#      wait_for_ajax
#      page.find('#easy_button_is_private').set(false)
#      page.find("input[type='submit']").click
#
#      logged_user(different_user)
#      visit(issue_path(issue))
#      wait_for_ajax
#      expect(page).to have_css('.easy-action-button', :count => 1)
#
#      EasyButton.last.safe_destroy
#      issue.reload
#      visit(issue_path(issue))
#      wait_for_ajax
#      expect(page).to have_css('.easy-action-button', :count => 0)
#    end
#  end
#end
