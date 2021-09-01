require 'easy_extensions/spec_helper'

describe EpmChartQuery, logged: :admin, skip: !Redmine::Plugin.installed?(:easy_gantt_resources) do

  def set_query_settings(name, options)
    settings[name] = options
  end

  def get_show_data(page_context = {})
    page_module.get_show_data(settings, User.current, page_context)
  end

  let(:page_module) { described_class.new }
  let(:settings) { {'easy_query_type' => 'EasyLightResourceQuery', 'query_type' => '2'} }
  let(:page_context) { {} }

  context 'easy_sprint' do
    let!(:sprint) { FactoryBot.create(:easy_sprint) }
    let!(:res1) { FactoryBot.create(:easy_gantt_resource, issue: issue1) }
    let!(:res2) { FactoryBot.create(:easy_gantt_resource, issue: issue2) }
    let!(:issue1) { FactoryBot.create(:issue, easy_sprint_id: sprint.id) }
    let!(:issue2) { FactoryBot.create(:issue) }

    it 'get_show_data' do
      # without global filters
      query = get_show_data[:query]
      expect(query.filters).to eq({})
      expect(query.entities).to match_array([res1, res2])

      # with global filters
      set_query_settings('global_filters', {'1' => {'filter' => 'issues.easy_sprint_id'}})
      query = get_show_data({active_global_filters: {'1' => sprint.id.to_s}})[:query]
      expect(query.filters).to eq({'issues.easy_sprint_id' => {'operator' => '=', 'values' => [sprint.id.to_s]}})
      expect(query.entities).to match_array([res1])
    end

    it 'query filters' do
      set_query_settings('fields', ['issues.easy_sprint_id'])
      set_query_settings('operators', { 'issues.easy_sprint_id' => '=' })
      set_query_settings('values', { 'issues.easy_sprint_id' => [sprint.id.to_s] })

      query = get_show_data[:query]
      expect(query.filters).to eq({'issues.easy_sprint_id' => {'operator' => '=', 'values' => [sprint.id.to_s]}})
      expect(query.entities).to match_array([res1])
    end
  end
end
