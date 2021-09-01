require 'easy_extensions/spec_helper'

RSpec.describe 'EpmScheduler', logged: :admin, if: Redmine::Plugin.installed?(:easy_scheduler) do

  def change_options(options = [])
    settings['query_settings']['settings']['selected_principal_ids'] = options
  end

  let(:page_module) { EpmScheduler.new }
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  let(:settings) {
    {
      'query_settings' => { 'settings' => { 'selected_principal_ids' => ['my_subordinates'] } }
    }
  }

  before do
    tree = {'id' => user2.to_gid_param, 'children' => {'1' => {'id' => user1.to_gid_param}}}
    EasyOrgChartNode.create_nodes!({'id' => User.current.to_gid_param, 'children' => {'1' => tree}})
  end

  context 'get_edit_data' do
    it 'my_subordinates' do
      edit_data = page_module.get_edit_data(settings, User.current, {})
      expected = [{id: 'my_subordinates', value: "<< #{I18n.t(:label_my_subordinates)} >>"}]

      expect(edit_data[:selected_principal_options]).to match_array(expected)
    end

    it 'my_subordinates_tree' do
      change_options(['my_subordinates_tree'])
      edit_data = page_module.get_edit_data(settings, User.current, {})
      expected = [{id: 'my_subordinates_tree', value: "<< #{I18n.t(:label_my_subordinates_tree)} >>"}]

      expect(edit_data[:selected_principal_options]).to match_array(expected)
    end
  end

  context 'get_show_data' do
    it 'my_subordinates' do
      show_data = page_module.get_show_data(settings, User.current, {})
      scheduler_settings = show_data[:scheduler_settings]

      expect(scheduler_settings).to include('selected_user_ids' => [user2.id])
    end

    it 'my_subordinates' do
      change_options(['my_subordinates_tree'])
      show_data = page_module.get_show_data(settings, User.current, {})
      scheduler_settings = show_data[:scheduler_settings]

      expect(scheduler_settings['selected_user_ids']).to match_array([user2.id, user1.id])
    end
  end
end
