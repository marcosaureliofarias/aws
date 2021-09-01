require 'easy_extensions/spec_helper'

feature 'easy sprints', logged: :admin, js: true do

  let(:project) { FactoryBot.create(:project, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:sprint) { FactoryBot.create(:easy_sprint, project: project) }

  it 'new' do
    visit new_easy_sprint_path(project_id: project.id)
    wait_for_ajax
    expect(page.find("#easy_sprint_capacity")).to be_disabled
    expect(page.find("#easy_sprint_summable_column_for_burndown").value).to eq('')
    page.find("#easy_sprint_summable_column_for_burndown option[value='easy_story_points']").select_option
    wait_for_ajax
    expect(page.find("#easy_sprint_capacity")).not_to be_disabled
    page.find("#easy_sprint_name").set('sprintname')
    page.find(".form-actions .button-positive").click
    wait_for_ajax
    page.execute_script "EASY.utils.toggleSidebar();"
    expect(page.find("#sprint_id_autocomplete").value).to eq('sprintname')
  end

end
