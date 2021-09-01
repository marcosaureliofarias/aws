require 'easy_extensions/spec_helper'

feature 'attendance module', :js => true, :js_wait => :long, :logged => :admin do
  let!(:my_attendance) { FactoryGirl.create(:easy_attendance, :arrival => Date.today.to_time + 7.hours, :user => User.current) }
  let!(:easy_attendance) { FactoryGirl.create(:easy_attendance, :arrival => Date.today.to_time + 7.hours) }

  def select_module(name, zone)
    within("#list-#{zone}") { select name, :from => 'module_id' }
    wait_for_ajax
  end

  scenario 'my attendance' do
    visit '/my/page_layout'
    select_module(I18n.t(:attendance, :scope => :'easy_pages.modules'), 'top')
    wait_for_late_scripts
    save_easy_page_modules
    expect(page.find('div.easy-attendances')).to have_content(User.current.name)
    expect(page.find('div.easy-attendances')).not_to have_content(easy_attendance.user.name)
  end

  scenario 'without default filters' do
    visit '/my/page_layout'
    select_module(I18n.t(:attendance, :scope => :'easy_pages.modules'), 'top')

    page.find('.easy-query-type-settings-container .easy-query-type-settings-container-filters').click
    page.find(".filters-table input[value='arrival']").set(false) # remove default filters
    page.find(".filters-table input[value='user_id']").set(false)
    save_easy_page_modules
    expect(page.find('div.easy-attendances')).to have_content(User.current.name)
    expect(page.find('div.easy-attendances')).to have_content(easy_attendance.user.name)

    visit '/my/page_layout'
    wait_for_ajax
    within('.module-toggle-button') { find('.expander').click }

    page.find('.easy-query-type-settings-container .easy-query-type-settings-container-filters').click
    expect(page).not_to have_css(".filters-table input[value='arrival']")
    expect(page).not_to have_css(".filters-table input[value='user_id']")
  end
end
