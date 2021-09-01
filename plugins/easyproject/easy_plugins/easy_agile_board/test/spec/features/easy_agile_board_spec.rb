require 'easy_extensions/spec_helper'

RSpec.describe 'Easy Agile Board', type: :feature, logged: :admin do

  let(:project) { FactoryGirl.create(:project, number_of_members: 3, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:issues) { FactoryGirl.create_list(:issue, 5, project: project, assigned_to: nil, easy_sprint_id: EasySprint.last.id) }
  let(:issue) { FactoryGirl.create(:issue, project: project, assigned_to: nil, easy_sprint: EasySprint.last) }
  let(:sprints) { FactoryGirl.create_list(:easy_sprint, 3, project: project) }
  let(:deploy_status) { FactoryGirl.create(:issue_status, name: 'Deploy') }
  let(:statuses_setting) { { 'agile_board_statuses' => {
    'done' => { 'status_id' => '' },
    'progress' =>
      { '1' => { 'name' => 'New', 'status_id' => '' },
        '2' => { 'name' => 'Realization', 'status_id' => '' },
        '3' => { 'name' => 'To check', 'status_id' => '' },
        '4' => { 'name' => 'Deploy', 'state_statuses' => [deploy_status.id.to_s], 'status_id' => deploy_status.id.to_s } }
  }
  }
  }

  # it 'display button on project page' do
  #   visit project_path(project)
  #   expect(page).to have_css('a.button-positive', text: 'Agile board')
  # end

  # it 'display project team and project backlog', js: true do
  #   sprints
  #   issues
  #   sprint = sprints.last
  #   visit easy_agile_board_path(project, :sprint_id => sprint.id)
  #   expect(page).to have_css('a', text: 'Coworkers')
  #   page.find('a', text: 'Coworkers').click
  #   project.users.each do |u|
  #     expect(page).to have_css('#coworkers_container .member', text: u.name)
  #   end
  #   issues.each do |i|
  #     expect(page).to have_css(".backlog li#el-#{i.id.to_s} .issue-link", text: i.to_s)
  #   end
  # end

  # it 'display swimlanes', js: true do
  #   sprints
  #   issues
  #   sprint = sprints.last
  #   visit easy_agile_board_path(project, :sprint_id => sprint.id)
  #   expect(page).not_to have_css('.agile-listing-links-actions a.icon-group.active')
  #   page.find('.agile-listing-links-actions a.icon-group').click
  #   wait_for_ajax
  #   expect(page).to have_css('.agile-listing-links-actions a.icon-group.active')
  #   expect(page).to have_css('.swimlane_worker', :count => 2)
  # end

  # it 'display existing sprints', js: true do
  #   sprints
  #   visit easy_agile_board_path(project)
  #   expect(page).to have_css('div.easy-sprint', count: 1)
  # end

  it 'create new sprint', js: true do
    visit easy_agile_board_path(project)
    expect(page).to have_css('#new_easy_sprint')
    page.find('input[name="commit"]').click
    expect(page).to have_css('#errorExplanation', text: 'Name cannot be blank')
    fill_in 'easy_sprint_name', with: 'Some new sprint'
    page.find('input[name="commit"]').click
    wait_for_ajax
    page.execute_script "EASY.utils.toggleSidebar();"
    expect(page.find('#sprint_id_autocomplete').value).to eq 'Some new sprint'
  end

  context 'group assignments', js: true do
    let(:group) { FactoryGirl.create(:group) }
    let(:group_issue) { FactoryGirl.create(:issue, project: project, assigned_to: group, easy_sprint_id: EasySprint.last.id) }

    before(:each) { sprints; group_issue }

    # it 'gravatars' do
    #   with_settings(:gravatar_enabled => '1') do
    #     sprint = sprints.last
    #     visit easy_agile_board_path(project, :sprint_id => sprint.id)
    #     expect(page).to have_css('.issue-link', :count => 1)
    #   end
    # end

    # it 'avatars' do
    #   with_settings(:gravatar_enabled => '0') do
    #     sprint = sprints.last
    #     visit easy_agile_board_path(project, :sprint_id => sprint.id)
    #     expect(page).to have_css('.issue-link', :count => 1)
    #   end
    # end
  end

  def find_backlogs
    sprint_backlog = page.find('.agile__list.backlog-column-sprint')
    project_backlog = page.find('.agile__list.backlog-column-backlog')
    tasks_for_backlog = page.find('.agile__list.backlog-column-not-assigned')
    [sprint_backlog, project_backlog, tasks_for_backlog]
  end

  it 'drag issue from and to sprint backlog', js: true do
    sprints; issues
    sprint = sprints.last
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    issue = sprint_backlog.find('.agile__card', match: :first)
    issue_text = issue.find('.agile__card__title').text
    issue.drag_to(project_backlog)
    wait_for_ajax
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    expect(project_backlog).to have_css('.agile__card', count: 1, text: issue_text)

    issue = sprint_backlog.find('.agile__card', match: :first)
    issue_text = issue.find('.agile__card__title').text
    issue.drag_to(tasks_for_backlog)
    wait_for_ajax
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    expect(tasks_for_backlog).to have_css('.agile__card', count: 1, text: issue_text)

    issue = project_backlog.find('.agile__card', match: :first)
    issue_text = issue.find('.agile__card__title').text
    issue.drag_to(sprint_backlog)
    wait_for_ajax
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    expect(sprint_backlog).to have_css('.agile__card', count: 1, text: issue_text)

    issue = tasks_for_backlog.find('.agile__card', match: :first)
    issue_text = issue.find('.agile__card__title').text
    issue.drag_to(sprint_backlog)
    wait_for_ajax
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    expect(sprint_backlog).to have_css('.agile__card', count: 1, text: issue_text)
  end

  it 'drag issue between backlogs', js: true do
    sprints; issues
    sprint = sprints.last
    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs

    issue = sprint_backlog.find('.agile__card', match: :first)
    issue_text1 = issue.find('.agile__card__title').text
    issue.drag_to(project_backlog)
    wait_for_ajax

    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    issue = sprint_backlog.find('.agile__card', match: :first)
    issue_text2 = issue.find('.agile__card__title').text
    issue.drag_to(tasks_for_backlog)
    wait_for_ajax

    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    issue = tasks_for_backlog.find('.agile__card', :text => issue_text2)
    issue.drag_to(project_backlog)
    wait_for_ajax

    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    issue = project_backlog.find('.agile__card', :text => issue_text1)
    issue.drag_to(tasks_for_backlog)
    wait_for_ajax

    visit easy_agile_board_backlog_path(project, sprint)
    sprint_backlog, project_backlog, tasks_for_backlog = find_backlogs
    expect(tasks_for_backlog).to have_css('.agile__card__title', count: 1, text: issue_text1)
    expect(project_backlog).to have_css('.agile__card__title', count: 1, text: issue_text2)
    expect(sprint_backlog).not_to have_css('.agile__card__title', text: issue_text1)
    expect(sprint_backlog).not_to have_css('.agile__card__title', text: issue_text2)
  end

  it 'drag issue from project backlog to custom progress state', js: true do
    sprints
    sprint = sprints.last
    issue = issues.first
    with_easy_settings(statuses_setting) do
      visit easy_agile_board_path(project, :sprint_id => sprint.id)
      issue_el = page.find(".item_#{issue.id}").find('.agile__card')
      issue_text = issue_el.find('.agile__card__title').text
      custom_deploy = page.find("[data-column-name='Deploy']")

      issue_el.drag_to(custom_deploy)
      wait_for_ajax

      visit easy_agile_board_path(project, :sprint_id => sprint.id)

      expect(page).to have_css("[data-column-name='Deploy'] .item_#{issue.id}")

      expect(issue.reload.status).to eq(deploy_status)

    end
  end

  it 'drag and drop issue into swimline', js: true do
    sprints
    user = project.users.first
    issue
    sprint = sprints.last
    IssueEasySprintRelation.create(issue: issue, easy_sprint: sprint, relation_type: :backlog)
    with_easy_settings(statuses_setting) do
      visit easy_agile_board_path(project, :sprint_id => sprint.id)
      swimline_select = page.find('.agile__swimline-select').find('select')
      within swimline_select do
        find("option[value='assigned_to_id']").click
      end
      expect(page).to have_content(user.name)
      #expect(page).to have_content( issue.subject )
      issue_el = page.find(".item_#{issue.id}").find('.agile__card')
      row = page.find('.agile__swimline', text: user.name)
      custom_deploy = row.find("[data-column-name='Deploy']")

      issue_el.drag_to(custom_deploy)
      wait_for_ajax

      visit easy_agile_board_path(project, :sprint_id => sprint.id)
      row = page.find('.agile__swimline', text: user.name)
      expect(row).to have_css("[data-column-name='Deploy'] .item_#{issue.id}")

      expect(issue.reload.status).to eq(deploy_status)
      expect(issue.assigned_to_id).to eq(user.id)

    end
  end

  # it 'deleted sprint should disappear right after click', js: true do
  #   sprint = sprints.last
  #   visit easy_agile_board_path(project, :sprint_id => sprint)
  #
  #   page.find('#easy_sprint_head', text: sprint.name).find('.icon-del').click
  #   expect(page).not_to have_css("#easy-sprint-#{sprint.id}")
  #   expect(page).not_to have_css("#easy-sprint-container-#{sprint.id}")
  # end

  # it 'change issue_status on issue', js: true do
  #   sprints
  #   sprint = sprints.last
  #   issue = issues.first
  #   with_easy_settings(statuses_setting) do
  #     visit easy_agile_board_path(project, :sprint_id => sprint.id)
  #     expect(page).not_to have_css(".agile-list.progress[data-relation-position='4'] li#el-#{issue.id}")
  #
  #     issue.status = deploy_status
  #     issue.save
  #
  #     visit easy_agile_board_path(project, :sprint_id => sprint.id)
  #
  #     expect(issue.reload.status).to eq(deploy_status)
  #     expect(page).to have_css("#easy-sprint-container-#{sprints.last.id} .agile-list.progress[data-relation-position='4']")
  #     expect(page).to have_css(".agile-list.progress[data-relation-position='4'] li#el-#{issue.id}")
  #   end
  # end

  context 'project cf' do
    let(:project_custom_fields) { FactoryGirl.create_list(:project_custom_field, 3, is_for_all: false) }
    let(:project_custom_value1) { CustomValue.create(customized: project, custom_field: project_custom_fields.last, value: 'test_cf1') }
    let(:project_custom_value2) { CustomValue.create(customized: project, custom_field: project_custom_fields.first, value: 'test_cf2') }

    # it 'cf description', js: true do
    #   sprints
    #   issues
    #   sprint = sprints.last
    #   project_custom_value1
    #   project_custom_value2
    #   project.project_custom_fields = project_custom_fields
    #   project.save
    #   project.reload
    #   with_easy_settings({'easy_agile_project_cf' => project_custom_fields.last.id.to_s}, project) do
    #     visit easy_agile_board_path(project, :sprint_id => sprint.id)
    #     expect(page.find('#agile_sprint_container')).to have_content(project_custom_value1.value)
    #   end
    # end
  end

  context 'query' do
    let(:sprint_none_query) { FactoryGirl.create(:easy_issue_query, filters: { sprint_id: nil }) }

    # it 'issues without sprint', js: true do
    #   sprint_none_query
    #   sprints
    #   sprint = sprints.last
    #   visit easy_agile_board_backlog_path(project, sprint)
    #   page.find('#easy-query-toggle-button-filters').click
    #   wait_for_ajax
    #   sleep 0.5
    #   page.find("#add_filter_select optgroup[label='#{I18n.t(:'easy_query.name.easy_agile_board_query')}'] option[value='easy_sprint_id']").select_option
    #   page.find("#operators_easy_sprint_id option[value='!*']").select_option
    #   page.find('#filter_buttons a.apply-link').click
    #   expect(page).to have_css("#easy-query-toggle-button-filters .active-filters")
    # end
  end

  context 'qoal' do
    let(:sprints_without_goal) { FactoryGirl.create(:easy_sprint, project: project, goal: '') }
    let(:sprints_with_goal) { FactoryGirl.create(:easy_sprint, project: project, goal: 'test goal show') }

    # it 'sprint with goal' do
    #   visit easy_agile_board_path(project, :sprint_id => sprints_with_goal.id)
    #   expect(page).to have_text(I18n.t(:label_easy_sprint_goal))
    #   expect(page).to have_text('test goal show')
    # end

    it 'sprint without goal' do
      visit easy_agile_board_path(project, sprint_id: sprints_without_goal.id)
      expect(page).to_not have_text(I18n.t(:label_easy_sprint_goal))
    end
  end

  # it 'sticky line', js: true do
  #   sprints
  #   issues
  #   visit issues_path(outputs: ['kanban'], settings: {kanban: {kanban_group: 'status'}})
  #   wait_for_ajax
  #   page.find(".agile__group-select select option[value='tracker_id']").select_option
  #   wait_for_ajax
  #   expect(page).to have_css(".sticky_swimlane", text: issues.first.tracker.name)
  #
  #   page.find(".agile__sticky-selector button").click
  #   expect(page).to have_css(".agile__group-select")
  # end

end
