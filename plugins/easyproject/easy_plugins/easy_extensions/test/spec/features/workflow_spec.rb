require 'easy_extensions/spec_helper'

feature 'workflow', js: true, logged: true do

  let(:project) { FactoryGirl.create(:project, :members => [User.current]) }
  let(:issue_status1) { FactoryGirl.create(:issue_status) }
  let(:issue_status2) { FactoryGirl.create(:issue_status) }
  let(:issue) { FactoryGirl.create(:issue, :project => project, :status => issue_status1) }

  scenario 'show custom fields after status change' do
    project
    role = User.current.reload.roles.first
    role.add_permission! :edit_issues
    WorkflowTransition.create!(:role_id => role.id, :tracker_id => issue.tracker.id, :old_status_id => issue_status1.id, :new_status_id => issue_status2.id)
    WorkflowPermission.create!(:old_status_id => issue_status1.id, :tracker_id => issue.tracker.id, :role_id => role.id, :field_name => 'due_date', :rule => 'readonly')
    visit edit_issue_path(issue)
    expect(page).not_to have_css('#issue_due_date')
    page.find("#issue_status_id option[value='#{issue_status2.id}']").select_option
    wait_for_ajax
    expect(page).to have_css('#issue_due_date')
  end

  scenario 'preload workflow rules' do
    project
    role = User.current.reload.roles.first
    role.add_permission! :edit_issues
    issue
    visit issues_path
    expect(page).to have_css("tr#entity-#{issue.id} .priority .icon-edit", :visible => false)

    WorkflowTransition.create!(:role_id => role.id, :tracker_id => issue.tracker.id, :old_status_id => issue_status1.id, :new_status_id => issue_status2.id)
    WorkflowPermission.create!(:old_status_id => issue_status1.id, :tracker_id => issue.tracker.id, :role_id => role.id, :field_name => 'priority_id', :rule => 'readonly')

    visit issues_path
    expect(page).not_to have_css("tr#entity-#{issue.id} .priority .icon-edit", :visible => false)
  end
end
