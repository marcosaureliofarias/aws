require 'easy_extensions/spec_helper'

feature 'settings', js: true, logged: :admin do
  scenario 'general' do
    visit settings_path
    wait_for_ajax
    expect(page).to have_css('#settings_app_title')
    expect(page).to have_css(".form-actions input[type='submit']")
    expect(page).to have_css('#tab-general.selected')
  end
end
