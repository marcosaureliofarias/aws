RSpec.shared_context 'easy pages' do

  let(:easy_page) { EasyPage.find_by(page_name: 'my-page') }

  let(:easy_page_available_zones_id) { EasyPageAvailableZone.first.id }
  let(:easy_page_available_modules_id) { EasyPageAvailableModule.first.id }

end

RSpec.shared_context 'easy page tabs' do
  include_context 'easy pages'

  let(:easy_page_user_tab) {
    EasyPageUserTab.create!(page_definition: easy_page,
                            user:            User.current,
                            position:        1,
                            name:            'my_tab')
  }

  let(:easy_page_zone_module) {
    EasyPageZoneModule.create!(page_definition:                easy_page,
                               user:                           User.current,
                               easy_page_available_zones_id:   easy_page_available_zones_id,
                               easy_page_available_modules_id: easy_page_available_modules_id,
                               settings:                       HashWithIndifferentAccess.new,
                               tab_id:                         easy_page_user_tab.id)
  }
end

RSpec.shared_context 'easy page templates' do
  include_context 'easy pages'

  let(:easy_page_zone_module_with_template) {
    EasyPageZoneModule.create!(page_definition:                easy_page,
                               user:                           User.current,
                               easy_page_available_zones_id:   easy_page_available_zones_id,
                               easy_page_available_modules_id: easy_page_available_modules_id,
                               settings:                       HashWithIndifferentAccess.new)
  }

  let(:easy_page_template) {
    EasyPageTemplate.create!(easy_pages_id: easy_page_zone_module_with_template.easy_pages_id,
                             template_name: 'TestTemplate',
                             description:   'TestTemplate')
  }

  let(:easy_page_template_tab) {
    EasyPageTemplateTab.create!(page_template_definition: easy_page_template,
                                position:                 1,
                                name:                     'my_template_tab')
  }

  let(:easy_page_template_module) {
    EasyPageTemplateModule.create!(easy_page_templates_id:         easy_page_template.id,
                                   easy_page_available_zones_id:   EasyPageAvailableZone.first.id,
                                   easy_page_available_modules_id: EasyPageAvailableModule.second.id,
                                   tab_id:                         nil,
                                   settings:                       HashWithIndifferentAccess.new)
  }

  let(:easy_page_template_module_with_tab) {
    EasyPageTemplateModule.create!(easy_page_templates_id:         easy_page_template.id,
                                   easy_page_available_zones_id:   EasyPageAvailableZone.first.id,
                                   easy_page_available_modules_id: EasyPageAvailableModule.second.id,
                                   tab_id:                         easy_page_template_tab.id,
                                   settings:                       HashWithIndifferentAccess.new)
  }
end
