require_relative '../spec_helper'

describe EasyQueryHelper do
  let(:project) { FactoryBot.create(:project) }
  let(:easy_query) { FactoryBot.create(:easy_query, project: project) }

  describe '#retrieve query', logged: :admin do

    it 'temporarily overrides project of saved query when using dont_use_project option' do
      controller.params[:query_id] = easy_query.id
      assign(:project, project)
      allow(helper).to receive(:loading_group).and_return(nil)

      expect(helper.retrieve_query(EasyQuery, false, dont_use_project: true).project).to be_nil
    end

  end

  describe '#easy_query_selected_values' do
    let(:query) { EasyIssueQuery.new }
    let(:priority) { FactoryBot.create(:issue_priority) }

    it 'Principals: assigned_to_id' do
      query.filters = { "assigned_to_id" => { "operator" => "=", "values" => [User.current.id.to_s] } }
      expect(helper.easy_query_selected_values(query, 'assigned_to_id').split(', ')).to match_array([User.current.name])
    end

    it 'Enumeration: priority_id' do
      query.filters = { "priority_id" => { "operator" => "=", "values" => [priority.id.to_s] } }
      expect(helper.easy_query_selected_values(query, 'priority_id').split(', ')).to match_array([priority.to_s])
    end

  end
end
