require 'easy_extensions/spec_helper'

feature 'alerts', :js => true, :logged => :admin do
  let!(:alert_rule) { FactoryGirl.create(:alert_rule) }
  let!(:alert_type) { FactoryGirl.create(:alert_type, :is_default => true) }
  let!(:easy_issue_query) { FactoryGirl.create(:easy_issue_query, :visibility => EasyQuery::VISIBILITY_PUBLIC) }

  scenario 'save alert' do
    visit new_alert_path
    alert_name = 'test alert'
    page.find('#alert_name').set(alert_name)
    page.find("#alert_rule_id option[value='#{alert_rule.id}']").select_option
    wait_for_ajax
    page.find("#query_id option[value='#{easy_issue_query.id}']").select_option
    page.find("input[type='submit']").click
    expect(page.find('.list')).to have_content(alert_name)
    page.find('.easy-additional-ending-buttons a.icon-edit').click
    page.find("input[type='submit']").click
    expect(page.find('.list')).to have_content(alert_name)
  end
end
