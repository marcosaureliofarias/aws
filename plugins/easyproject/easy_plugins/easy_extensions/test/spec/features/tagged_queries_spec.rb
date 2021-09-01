require 'easy_extensions/spec_helper'

feature 'Tagged Queries', js: true, logged: :admin, js_wait: :long do

  let(:project) { FactoryGirl.create(:project, :with_subprojects) }
  let(:project2) { FactoryGirl.create(:project) }
  let(:tagged_query) { FactoryGirl.create(:easy_issue_query, :name => 'tagged',
                                          :is_tagged               => true, :visibility => 2, :project => project, :is_for_subprojects => true) }

  scenario 'visibility' do
    tagged_query; project.reload

    visit project_issues_path(project, :set_filter => 0)
    expect(page).to have_css('.easy-query-heading span.entity-name', :text => 'tagged', :count => 1)

    visit project_issues_path(project.children.first, :set_filter => 0)
    expect(page).to have_css('.easy-query-heading span.entity-name', :text => 'tagged', :count => 1)

    project2.reload
    visit project_issues_path(project2, :set_filter => 0)
    expect(page).not_to have_css('.easy-query-heading span.entity-name', :text => 'tagged', :count => 1)
  end

  scenario 'destroy' do
    tagged_query; project.reload

    visit project_issues_path(project, :set_filter => 1, :query_id => tagged_query)
    page.execute_script('$(".tooltip").show()')
    page.find('.easy-query-heading .icon-del').click
    #accept_confirm
    expect(current_path).not_to include('query_id')
    expect(page).to have_css('.easy-query-heading')
    page.execute_script('$(".tooltip").show()')
    expect(page).not_to have_css('.easy-query-heading icon-del')
  end
end
