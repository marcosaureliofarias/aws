require 'easy_extensions/spec_helper'

RSpec.describe EpmUsersUtilization, logged: :admin do

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
        'user_ids' => [User.current.id, user.id],
        'days' => 7,
        'global_filters' => {'1' => {'filter' => 'group_id'}}
      }
    }

    it 'by global group_id' do
      show_data = page_module.get_show_data(settings, User.current, page_context)

      expect(show_data).to include(hours: 5.0)
      expect(show_data).to include(from: Date.today)
      expect(show_data).to include(to: Date.today + 7.days)
      expect(show_data[:users]).to match_array(Array(user))
    end

    it 'no global filter' do
      show_data = page_module.get_show_data(settings, User.current, {active_global_filters: {}}) # page module doesnt have global group_id

      expect(show_data[:users]).to match_array(Array([User.current, user]))
    end
  end
end
