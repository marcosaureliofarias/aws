require_relative '../spec_helper'

RSpec.describe Redmine::MenuManager::MenuHelper, type: :helper do

  context '#render_easy_custom_menu' do

    def test_selected_items(user, fullpath, selected_count)
      allow(helper.request).to receive(:fullpath).and_return(fullpath)

      result = helper.render_easy_custom_menu(user)
      expect(result.scan(/selected/).size).to eq(selected_count)
    end

    it 'url match items' do
      custom_menu_1 = EasyCustomMenu.new(name: 'aaa', url: '/issues')
      custom_menu_2 = EasyCustomMenu.new(name: 'bbb', url: '/issues?bbb=1')

      user_type = FactoryBot.create(:easy_user_type, easy_custom_menus: [custom_menu_1, custom_menu_2])
      user      = FactoryBot.create(:user, easy_user_type: user_type)

      allow(helper).to receive(:current_menu_item).and_return('')

      test_selected_items(user, '/', 0)
      test_selected_items(user, '/issues', 1)
      test_selected_items(user, '/issues?bbb=1', 1)
      test_selected_items(user, '/issues?bbb=2', 0)
    end

  end

end
