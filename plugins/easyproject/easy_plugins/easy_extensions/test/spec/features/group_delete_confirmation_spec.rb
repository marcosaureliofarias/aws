require 'easy_extensions/spec_helper'

feature 'delete group', js: true, logged: :admin do

  let(:group) { FactoryBot.create(:group) }
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role) }

  scenario 'if no relations' do
    group
    visit_groups_index_and_click_delete
    expect(page.evaluate_script('window.confirmClicked')).to be(true)
    expect(page).not_to have_css('.ui-dialog-title')
  end

  scenario 'if included into a project' do
    group
    project
    project.members << Member.new(project: project, principal: group, roles: [role]);
    visit_groups_index_and_click_delete
    expect(page.evaluate_script('window.confirmClicked')).to be(false)
    expect(page).to have_css('.ui-dialog-title')
  end

  scenario 'if contains a user' do
    group
    project
    user
    group.members << Member.new(project: project, principal: group, roles: [role]);
    visit_groups_index_and_click_delete
    expect(page.evaluate_script('window.confirmClicked')).to be(false)
    expect(page).to have_css('.ui-dialog-title')
  end

  private

  def visit_groups_index_and_click_delete
    visit groups_path
    page.evaluate_script('window.confirmClicked = false')
    page.evaluate_script('window.confirm = function() { window.confirmClicked = true }')
    page.find('table.list.groups td.buttons a.icon-del').click
    wait_for_ajax
  end

end
