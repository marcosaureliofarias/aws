require 'easy_extensions/spec_helper'

RSpec.describe EpmAllocatedResources, logged: :admin do

  # "x" because
  # 1. The page module is still a beta
  # 2. Its too much work to handle
  #    - week starts (Sunday or Monday)
  #    - first week of the year (0 vs 1)
  #
  # Also all of this works on regular page module graph with query LightResource
  #
  xcontext 'global filters' do
    let!(:group) { FactoryBot.create(:group) }
    let(:user) { FactoryBot.create(:user, groups: [group]) }
    let(:range) { {from: Date.today - 1.day, to: Date.today + 1.day} }
    let!(:resource1) { FactoryBot.create(:easy_gantt_resource, date: range[:from], user_id: user.id) }
    let!(:resource2) { FactoryBot.create(:easy_gantt_resource, date: range[:from], user_id: User.current.id) }
    let(:page_module) { described_class.new }
    let(:page_context) {
      {active_global_filters: {'1' => group.id}}
    }
    let(:settings) {
      {
        'global_filters' => {'1' => {'filter' => 'group_id'}}
      }
    }

    before do
      allow_any_instance_of(described_class).to receive(:chart_range).and_return(range)
    end

    it 'by global group_id' do
      show_data = page_module.get_show_data(settings, User.current, page_context)

      expect(show_data).to include(range: range)
      expect(show_data[:values]).to match_array([{resource: 5.0, time_entry: 0.0, x: range[:from].strftime('%Y-%W')}])
    end

    it 'no global filter' do
      show_data = page_module.get_show_data(settings, User.current, {active_global_filters: {}}) # page module doesnt have global group_id

      expect(show_data[:values]).to match_array([{resource: 10.0, time_entry: 0.0, x: range[:from].strftime('%Y-%W')}])
    end
  end
end
