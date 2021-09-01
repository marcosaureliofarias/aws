require 'easy_extensions/spec_helper'

describe EasyPageTemplatesController do
  describe 'page templates', logged: :admin do
    render_views
    let(:template) { EasyPageTemplate.create(:easy_pages_id => 1, :template_name => 'TestTemplate', :description => 'TestTemplate', :is_default => true) }
    let(:template_module) { EasyPageTemplateModule.create(:easy_page_templates_id       => template.id,
                                                          :easy_page_available_zones_id => 1, :easy_page_available_modules_id => 13, :tab_id => nil, :settings => HashWithIndifferentAccess.new) }

    it 'show page template' do
      get :show_page_template, :params => { :id => template.id }
    end

    it 'edit page template' do
      get :edit_page_template, :params => { :id => template.id }
    end

    it 'show page template with module' do
      template_module
      get :show_page_template, :params => { :id => template.id }
    end

    it 'edit page template with module' do
      template_module
      get :edit_page_template, :params => { :id => template.id }
    end

    describe 'Copy tabs feature' do
      let(:easy_page) { FactoryBot.create(:easy_page, has_template: true) }
      let(:easy_page_user_tab1) { EasyPageUserTab.create(page_definition: easy_page, user: User.current, position: 1, name: 'my_tab1') }
      let(:easy_page_user_tab2) { EasyPageUserTab.create(page_definition: easy_page, user: User.current, position: 2, name: 'my_tab2') }
      let(:easy_page_zone_module1) {
        EasyPageZoneModule.create(page_definition: easy_page,
                                  user: User.current,
                                  easy_page_available_zones_id: 1,
                                  easy_page_available_modules_id: 13,
                                  settings: HashWithIndifferentAccess.new,
                                  tab_id: easy_page_user_tab1.id)
      }
      let(:easy_page_zone_module2) {
        EasyPageZoneModule.create(page_definition: easy_page,
                                  user: User.current,
                                  easy_page_available_zones_id: 1,
                                  easy_page_available_modules_id: 13,
                                  settings: HashWithIndifferentAccess.new,
                                  tab_id: easy_page_user_tab2.id)
      }

      context 'when params present' do
        it 'create new module' do
          easy_page_zone_module2
          params = {
              easy_pages_id: easy_page.id,
              copy_from_type: 'regular_page',
              copy_from_user_id: User.current.id,
              copy_from_tab_id: easy_page_zone_module1.tab_id,
              template_name: 'Test'
          }
          expect { post :create, params: { easy_page_template: params } }.to change(EasyPageTemplateModule, :count).by(1)
        end
      end

      context 'when params missing' do
        it 'returns 404' do
          post :create, params: { easy_page_template: {} }
          expect(response).to have_http_status(404)
        end
      end
    end
  end

end
