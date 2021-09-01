require 'easy_extensions/spec_helper'

feature 'roles', js: true, logged: :admin do
  let(:role) { FactoryBot.create(:role) }

  scenario 'open a dialog about permission dependencies' do
    visit edit_role_path(role)
    wait_for_ajax
    page.find('#role_permissions_edit_project').click
    expect(page).to have_css(".ui-dialog-title", text: I18n.t(:text_permission_dependencies_unsatisfied, state: 'disable'))
  end
end
