require 'easy_extensions/spec_helper'

feature 'easy user read entry', :js => true, :logged => :admin do

  let(:project) { FactoryGirl.create(:project, number_of_issues: 3) }
  let(:viewer) { FactoryGirl.create(:user, admin: true) }
  before(:each) { project.reload; logged_user(viewer) }

  scenario 'check icon' do
    visit issues_path(:project_id => project.id)
    EasyJob.wait_for_all
    expect(page).to have_css('.list.issues tbody tr', :count => 3)
    expect(page).to have_css('.list.issues tbody tr .unread', :count => 3)
    visit issue_path(project.issues.first)
    EasyJob.wait_for_all
    expect(page).to have_css('#content')
    visit issues_path(:project_id => project.id)
    EasyJob.wait_for_all
    expect(page).to have_css('.list.issues tbody tr .unread', :count => 2)
  end

  scenario 'check filter' do
    visit issue_path(project.issues.first)
    expect(page).to have_css('#content')
    visit issues_path(set_filter: 1, read_by: 'me', project_id: project.id)

    expect(page).to have_css('.list.issues tbody tr', count: 1)
    expect(page).not_to have_css('.list.issues tbody tr .unread')

    page.find('#easy-query-toggle-button-filters').click
    wait_for_ajax
    page.find("#operators_read_by option[value='!']").select_option
    page.find('#filter_buttons .apply-link').click

    expect(page).to have_css('.list.issues tbody tr', count: 2)
    expect(page).to have_css('.list.issues tbody tr .unread', count: 2)
  end

end
