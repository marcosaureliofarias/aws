require 'easy_extensions/spec_helper'

RSpec.describe EpmGroupsUtilization, logged: :admin do

  context 'global filters' do
    let!(:group) { FactoryBot.create(:group) }
    let(:page_module) { described_class.new }
    let(:page_context) {
      {active_global_filters: {'1' => group.id}}
    }
    let(:settings) {
      {
        'days' => 30,
        'groups_id' => 555,
        'global_filters' => {'1' => {'filter' => 'group_id'}}
      }
    }

    it 'by global group_id' do
      show_data = page_module.get_show_data(settings, User.current, page_context)

      expect(show_data).to include(additional_filters: {'group_id' => group.id})
      expect(show_data).to include(days: 30)
      expect(show_data[:groups]).to match_array(Array(group))
    end

    it 'by groups_id' do
      settings['groups_id'] = (page_module_group = FactoryBot.create(:group)).id
      show_data = page_module.get_show_data(settings, User.current, {active_global_filters: {'2' => User.current.id}}) # page module doesnt have global group_id

      expect(show_data[:groups]).to match_array(Array(page_module_group))
    end
  end
end
