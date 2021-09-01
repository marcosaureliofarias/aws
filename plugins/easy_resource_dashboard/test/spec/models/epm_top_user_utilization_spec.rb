require 'easy_extensions/spec_helper'

RSpec.describe EpmTopUserUtilization, logged: :admin do

  context 'global filters' do
    let!(:group) { FactoryBot.create(:group) }
    let(:user) { FactoryBot.create(:user, groups: [group]) }
    let!(:resource) { FactoryBot.create(:easy_gantt_resource, user_id: user.id) }
    let(:page_module) { described_class.new }
    let(:page_context) {
      {active_global_filters: {'1' => group.id}}
    }
    let(:settings) {
      {
        'count' => 30,
        'reverse' => 'true',
        'global_filters' => {'1' => {'filter' => 'group_id'}}
      }
    }

    it 'by global group_id' do
      show_data = page_module.get_show_data(settings, User.current, page_context)

      expect(show_data).to include(count: 30)
      expect(show_data).to include(reverse: true)
      expect(show_data[:top_users_utilizations]).to match_array(Array(user))
    end

    it 'no global filter' do
      show_data = page_module.get_show_data(settings, User.current, {active_global_filters: {}}) # page module doesnt have global group_id

      expect(show_data[:top_users_utilizations]).to match_array(Array([User.current, user]))
    end
  end
end
