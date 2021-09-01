require 'easy_extensions/spec_helper'

describe EasySprintsHelper do
  let(:project) { FactoryBot.create(:project) }
  let(:sprint) { FactoryBot.create(:easy_sprint, start_date: Date.new(2020, 1, 1), due_date: Date.new(2020, 1, 12), project: project, closed: 1) }
  let(:second_sprint) { FactoryBot.create(:easy_sprint, start_date: Date.new(2020, 1, 13), due_date: Date.new(2020, 1, 22), project: project, closed: 1) }
  let(:third_sprint) { FactoryBot.create(:easy_sprint, start_date: Date.new(2020, 1, 23), due_date: Date.new(2020, 2, 12), project: project) }

  it 'return link to next sprint if any' do
    project.easy_sprints << [sprint, second_sprint]

    expect(helper.easy_sprints_listing(sprint)).to include("<a class=\"next\" href=\"#{easy_agile_board_path(sprint.project_id, sprint_id: sprint.next_easy_sprint)}\"></a>")
  end

  it 'return link to previous and next if any' do
    project.easy_sprints << [sprint, second_sprint, third_sprint]

    expect(helper.easy_sprints_listing(second_sprint)).to include("<a class=\"prev\" href=\"#{easy_agile_board_path(second_sprint.project_id, sprint_id: second_sprint.reload.previous_easy_sprint)}\"></a><a class=\"next\" href=\"#{easy_agile_board_path(second_sprint.project_id, sprint_id: second_sprint.next_easy_sprint)}\"></a>")
  end

  it 'has no links and return "" if no sprints' do
    expect(helper.easy_sprints_listing(sprint)).to include("")
  end

end
