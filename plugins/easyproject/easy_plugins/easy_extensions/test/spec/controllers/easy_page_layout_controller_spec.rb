require 'easy_extensions/spec_helper'

describe EasyPageLayoutController do

  before(:all) {
    @my_page_id = 1
  }

  let(:user) { FactoryGirl.create(:user) }
  let(:available_module) { EasyPageAvailableModule.where(:easy_pages_id => @my_page_id).first }

  describe 'add_module' do
    before(:each) { logged_user(user) }

    it 'creates a new module on user page' do
      expect {
        post :add_module, :params => { :page_id => @my_page_id, :zone_id => 1, :user_id => user.id, :module_id => available_module.id }
      }.to change(EasyPageZoneModule.where(:user_id => user.id), :count).by(1)
    end

    it 'render a module template' do
      post :add_module, :params => { :page_id => @my_page_id, :zone_id => 1, :user_id => user.id, :module_id => EpmMyCalendar.first.id }
      expect(response).to render_template "easy_page_layout/_page_module_edit_container"
    end
  end

  describe '#remove_tab', logged: :admin do

    include_context 'easy page tabs'
    context 'one tab' do
      it 'not remove modules' do
        easy_page_zone_module
        tab_modules = easy_page.easy_page_tabs.first.user_tab_modules.values.flatten
        expect(tab_modules.count).not_to eq(0)
        expect(easy_page.easy_page_tabs.count).to eq(1)
        delete :remove_tab, params: { page_id: easy_page.id, user_id: User.current.id, tab_id: easy_page.easy_page_tabs.first.id, original_url: 'my_page' }
        expect(easy_page.easy_page_tabs.count).to eq(0)
        expect(easy_page.reload.all_modules).to eq(tab_modules)
      end
    end
  end

  context '#287576', logged: :admin do
    context 'copy tab' do
      include_context 'easy page tabs'

      it 'should copy a tab with all modules' do
        tab1 = EasyPageUserTab.find_by(id: easy_page_zone_module.tab_id)

        expect { put :add_tab, params: {
            page_id:        easy_page_zone_module.easy_pages_id,
            user_id:        User.current.id,
            tab_id_to_copy: easy_page_zone_module.tab_id
        } }.to change(EasyPageUserTab, :count).by(1)

        tab2 = assigns(:tab)

        zone_name = EasyPageAvailableZone.first.zone_definition.zone_name
        tab1_attr = tab1.user_tab_modules[zone_name].first.attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'id')
        tab2_attr = tab2.user_tab_modules[zone_name].first.attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'id')
        expect(tab1_attr).to eq(tab2_attr)
      end
    end

    context 'replace or add from template selected users' do
      include_context 'easy page templates'

      it 'replace' do
        template_module_attr = easy_page_template_module.attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'easy_page_templates_id', 'id')

        expect { put :layout_from_template_selected_users,
                     params: {
                         page_template_id: easy_page_template.id,
                         users:            [easy_page_zone_module_with_template.user_id],
                         easy_pages_id:    easy_page_zone_module_with_template.easy_pages_id,
                         method:           'replace'
                     } }.to change(EasyPageUserTab, :count).by(0)

        new_module_attr = EasyPageZoneModule.first.attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'user_id', 'easy_pages_id', 'id')
        expect(template_module_attr).to eq(new_module_attr)
      end

      it 'add to existing' do
        template_module_attr = easy_page_template_module.attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'easy_page_templates_id', 'id')

        expect(EasyPageUserTab.count).to eq(0)

        expect { put :layout_from_template_selected_users,
                     params: {
                         page_template_id: easy_page_template.id,
                         users:            [easy_page_zone_module_with_template.user_id],
                         easy_pages_id:    easy_page_zone_module_with_template.easy_pages_id,
                         method:           'add_tabs'
                     } }.to change(EasyPageUserTab, :count).by(2)

        new_tabs        = EasyPageUserTab.where(user_id: User.current)
        new_module_attr = EasyPageZoneModule.find_by(tab_id: new_tabs.second).attributes.except('tab_id', 'uuid', 'created_at', 'updated_at', 'user_id', 'easy_pages_id', 'id')

        expect(easy_page_zone_module_with_template).to eq(EasyPageZoneModule.find_by(tab_id: new_tabs.first))
        expect(template_module_attr).to eq(new_module_attr)
      end
    end

    it 'layout from template add replace' do
      page = EasyPage.find_by(page_name: 'my-page')
      get :layout_from_template_add_replace, params: { page_id: page.id }
      expect(assigns(:page)).to eq(page)
    end
  end
end
