require 'easy_extensions/spec_helper'

describe EpmChartQuery, logged: :admin do

  def set_query_settings(name, options)
    settings[name] = options
  end

  def get_show_data(page_context = {})
    page_module.get_show_data(settings, User.current, page_context)
  end

  let(:page_module) { described_class.new }
  let(:settings) { {'easy_query_type' => 'EasyLightResourceQuery', 'query_type' => '2'} } 
  let(:page_context) { {} }

  context 'fixed_version' do
    let(:version) { FactoryBot.create(:version, number_of_issues: 1) }
    let(:issue) { FactoryBot.create(:issue) }
    let!(:res1) { FactoryBot.create(:easy_gantt_resource, issue: version.fixed_issues.first) }
    let!(:res2) { FactoryBot.create(:easy_gantt_resource, issue: issue) }

    it 'get_show_data' do
      # without global filters
      query = get_show_data[:query]
      expect(query.filters).to eq({})
      expect(query.entities).to match_array([res1, res2])

      # with global filters
      set_query_settings('global_filters', {'1' => {'filter' => 'issues.fixed_version_id'}})
      query = get_show_data({active_global_filters: {'1' => version.id.to_s}})[:query]
      expect(query.filters).to eq({'issues.fixed_version_id' => {'operator' => '=', 'values' => [version.id.to_s]}})
      expect(query.entities).to match_array([res1])
    end

    it 'query filters' do
      set_query_settings('fields', ['issues.fixed_version_id'])
      set_query_settings('operators', { 'issues.fixed_version_id' => '=' })
      set_query_settings('values', { 'issues.fixed_version_id' => [version.id.to_s] })

      query = get_show_data[:query]
      expect(query.filters).to eq({'issues.fixed_version_id' => {'operator' => '=', 'values' => [version.id.to_s]}})
      expect(query.entities).to match_array([res1])
    end
  end
end
