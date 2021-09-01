require 'easy_extensions/spec_helper'

RSpec.describe EpmTrackersAllocations, logged: :admin do

  context 'global filters' do
    let!(:group) { FactoryBot.create(:group) }
    let(:user) { FactoryBot.create(:user, groups: [group]) }
    let(:issue) { FactoryBot.create(:issue, assigned_to_id: user.id) }
    let!(:resource1) { FactoryBot.create(:easy_gantt_resource, issue: issue) }
    let(:page_module) { described_class.new }
    let(:page_context) { {active_global_filters: {'1' => group.id}} }
    let(:settings) {
      {
        'tracker_ids' => [issue.tracker_id],
        'global_filters' => {'1' => {'filter' => 'group_id'}}
      }
    }

    it 'by global group_id' do
      show_data = page_module.get_show_data(settings, User.current, page_context)

      expect(show_data[:allocations_by_trackers]).to match_array([[issue.tracker.to_s, 5.0]])
    end

    it 'no global filter' do
      t = FactoryBot.create(:tracker)
      r = FactoryBot.create(:easy_gantt_resource, issue: FactoryBot.create(:issue, tracker: t))
      settings['tracker_ids'] = [issue.tracker_id, t.id]
      show_data = page_module.get_show_data(settings, User.current, {active_global_filters: {}}) # page module doesnt have global group_id

      expect(show_data[:allocations_by_trackers]).to match_array([[issue.tracker.to_s, 5.0], [t.to_s, 5.0]])
    end
  end
end
