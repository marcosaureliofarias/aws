require 'easy_extensions/spec_helper'

feature 'Easy Issue', js: true, logged: :admin do

  let(:project1) { FactoryGirl.create(:project, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:sprint1) { FactoryGirl.create(:easy_sprint, project: project1, cross_project: true) }
  let(:project2) { FactoryGirl.create(:project, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:issue) { FactoryGirl.create(:issue, project: project2, easy_sprint_id: sprint1.id) }
  let(:subpj_with_agile) { FactoryGirl.create(:project, number_of_issues: 0, parent: project1, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:subpj_without_agile) { FactoryGirl.create(:project, number_of_issues: 0, parent: project1) }
  let(:issue1) { FactoryGirl.create(:issue, project: subpj_with_agile) }
  let(:issue2) { FactoryGirl.create(:issue, project: subpj_without_agile) }
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:role_manager) { FactoryGirl.create(:role, permissions: [:view_issues, :edit_issues, :view_easy_scrum_board, :edit_easy_scrum_board]) }
  let(:role_worker) { FactoryGirl.create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member_manager1) { FactoryGirl.create(:member, project: project1, user: user1, roles: [role_manager]) }
  let(:member_worker1) { FactoryGirl.create(:member, project: project1, user: user2, roles: [role_manager]) }
  let(:member_manager2) { FactoryGirl.create(:member, project: subpj_with_agile, user: user1, roles: [role_manager]) }
  let(:member_worker2) { FactoryGirl.create(:member, project: subpj_with_agile, user: user2, roles: [role_worker]) }
  let(:member_manager3) { FactoryGirl.create(:member, project: subpj_without_agile, user: user1, roles: [role_manager]) }
  let(:member_worker3) { FactoryGirl.create(:member, project: subpj_without_agile, user: user2, roles: [role_worker]) }

  # scenario 'can see global sprints' do
  #
  #   visit_issue_with_edit_open(issue)
  #
  #   expect(page.find('#issue_easy_sprint_id').value).to eq(sprint1.id.to_s)
  # end

  # scenario 'on project with agile as manager' do
  #   member_manager1; member_manager2; member_manager3
  #
  #   logged_user(user1)
  #
  #   visit_issue_with_edit_open(issue1)
  #
  #   expect(page).to have_css('#issue_easy_sprint_id')
  # end

   scenario 'on project with agile as worker' do
    member_worker1; member_worker2; member_worker3

    logged_user(user2)

    visit_issue_with_edit_open(issue1)

    expect(page).not_to have_css('#issue_easy_sprint_id')
  end

  # scenario 'on project without agile as manager' do
  #   member_manager1; member_manager2; member_manager3
  #
  #   logged_user(user1)
  #
  #   visit_issue_with_edit_open(issue2)
  #
  #   expect(page).to have_css('#issue_easy_sprint_id')
  # end

  # scenario 'on project without agile as worker' do
  #   member_worker1; member_worker2; member_worker3
  #
  #   logged_user(user2)
  #
  #   visit_issue_with_edit_open(issue2)
  #
  #   expect(page).to have_css('#issue_easy_sprint_id')
  # end
end
