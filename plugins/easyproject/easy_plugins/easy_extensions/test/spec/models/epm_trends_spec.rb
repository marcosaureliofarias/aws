require 'easy_extensions/spec_helper'

describe 'epm trends', logged: :admin do
  let!(:projects) { FactoryBot.create_list(:project, 2, number_of_issues: 0) }
  let(:settings) { {"easy_query_type" => "EasyProjectQuery", "name" => "trend", "type" => "count"} }

  context 'show' do
    it 'count' do
      data = EpmTrends.new.get_show_data(settings, User.current)
      expect(data[:number_to_show]).to eq(2)
    end

    it 'count in a project context' do
      data = EpmTrends.new.get_show_data(settings, User.current, project: projects.first)
      expect(data[:number_to_show]).to eq(2)
    end

    it 'filter count in a project context' do
      filter = {"query" => {"set_filter" => "1", 'project_id' => [projects.first.id.to_s]}}
      data = EpmTrends.new.get_show_data(settings.merge(filter), User.current, project: projects.first)
      expect(data[:number_to_show]).to eq(1)
    end
  end

  context 'edit' do
    it 'get query' do
      data = EpmTrends.new.get_edit_data(settings, User.current)
      expect(data[:query].is_a?(EasyProjectQuery)).to eq(true)
    end
  end
end
