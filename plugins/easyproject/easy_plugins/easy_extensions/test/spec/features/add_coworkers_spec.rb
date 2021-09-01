require 'easy_extensions/spec_helper'

feature 'add coworkers', js: true, logged: :admin do

  let(:issue) { FactoryGirl.create(:issue) }

  scenario 'modal' do
    issue
    visit issues_path
    wait_for_ajax
    expect(page.find("#easy-query-heading-count")).to have_content('1')
    page.find('td.easy-query-additional-beginning-buttons').right_click
    x = page.find('#context-menu li', text: 'Coworkers')
    x.hover
    x.find('a.icon-add').click
    wait_for_ajax
    page.find("#ajax-modal input[type='search']").set('text')
    page.find("#ajax-modal #easy_query_q_button").click
    page.find('.ui-dialog-titlebar-close').click
    expect(page.find("#easy-query-heading-count")).to have_content('1')
    expect(page).to have_css('.freetext-search-contextual')
  end
end
