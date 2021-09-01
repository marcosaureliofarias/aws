require 'easy_extensions/spec_helper'

RSpec.describe EpmTrends, type: :model, logged: :admin, skip: !Redmine::Plugin.installed?(:easy_agile_board) do
  let(:project) { FactoryBot.create(:project) }
  let!(:issue1) { FactoryBot.create(:issue, project: project, estimated_hours: 10.0, easy_story_points: 1) }
  let(:issue1_first_allocation) { FactoryBot.create(:easy_gantt_resource, issue: issue1, user: User.current, custom: true, date: '2020-09-10', hours: 5.0) }
  let(:issue1_second_allocation) { FactoryBot.create(:easy_gantt_resource, issue: issue1, user: User.current, custom: false, date: '2020-09-11', hours: 5.0) }

  let!(:issue2) { FactoryBot.create(:issue, project: project, estimated_hours: 20.0, easy_story_points: 2) }
  let(:issue2_first_allocation) { FactoryBot.create(:easy_gantt_resource, issue: issue2, user: User.current, custom: true, date: '2020-09-12', hours: 15.0) }
  let(:issue2_second_allocation) { FactoryBot.create(:easy_gantt_resource, issue: issue2, user: User.current, custom: false, date: '2020-09-13', hours: 5.0) }

  let(:settings_sum_estimated_hours) { {'name' => 'name of filter',
                                        'easy_query_type' => 'EasyLightResourceQuery',
                                        'type' => 'sum',
                                        'column_to_sum' => 'issues.estimated_hours' } }

  let(:settings_sum_easy_story_points) { {'name' => 'name of filter',
                                          'easy_query_type' => 'EasyLightResourceQuery',
                                          'type' => 'sum',
                                          'column_to_sum' => 'issues.easy_story_points' } }

  let(:filter) { { 'query' => { 'set_filter' => '1', 'project_id' => [project.id.to_s] } } }

  it 'get query with sum estimated_hours' do
    data = EpmTrends.new.get_show_data(settings_sum_estimated_hours.merge(filter), User.current)
    expect(data[:query].is_a?(EasyLightResourceQuery)).to eq(true)
    expect(data[:number_to_show]).to eq(30)
  end

  it 'get query with sum easy_story_points' do
    data = EpmTrends.new.get_show_data(settings_sum_easy_story_points.merge(filter), User.current)
    expect(data[:query].is_a?(EasyLightResourceQuery)).to eq(true)
    expect(data[:number_to_show]).to eq(3)
  end
end