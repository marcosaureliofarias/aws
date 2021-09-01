require_relative '../spec_helper'

feature 'modal', js: true, logged: :admin do
  let(:issue) { FactoryBot.create(:issue) }

  scenario 'open' do
    issue
    visit issues_path
    wait_for_ajax
    page.find("#entity-#{issue.id} .icon-view-modal", visible: false).click
    wait_for_ajax
    expect(page).to have_css(".vue-modal__headline")
    expect(page).to have_css(".vue-modal__description")
  end

  scenario 'new task' do
    skip 'not implemented yet'
    visit issues_path
    wait_for_ajax
    page.execute_script("window.EasyVue.showModal(\"newIssue\")")
    wait_for_ajax
    expect(page).to have_css(".vue-modal__headline")
  end

  scenario 'scheduler', skip: !Redmine::Plugin.installed?(:easy_attendances) do
    visit issues_path
    wait_for_ajax
    page.execute_script("window.EasyVue.showModal(\"new_attendance\")")
    wait_for_ajax
    expect(page).to have_css(".vue-modal__headline")
  end
end
