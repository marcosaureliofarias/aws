require 'easy_extensions/spec_helper'

RSpec.describe 'burndown chart', js: true, logged: :admin do

  let(:project) { FactoryGirl.create(:project, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let(:sprint) { FactoryBot.create(:easy_sprint, project: project) }

  it 'show graph' do
    visit easy_agile_board_burndown_chart_path(project, sprint)
    wait_for_ajax
    expect(page).to have_css('#sprint_burndown_chart')
  end
end
