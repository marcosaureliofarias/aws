require 'easy_extensions/spec_helper'

describe EasyActivitiesController, logged: :admin do

  let(:project) { FactoryGirl.create(:project) }
  let(:issue) { FactoryGirl.create(:issue, project: project, author: User.current) }
  let(:journal) { Journal.create!(journalized: issue, user: User.current) }
  let(:detail) { JournalDetail.create!(journal_id: journal.id, property: 'attr', prop_key: 'status_id', old_value: '1', value: '2') }
  let(:page_module) {
    page            = EasyPage.find_by(page_name: 'project-overview')
    zone            = EasyPageZone.find_by(zone_name: 'top-left')
    available_zone  = EasyPageAvailableZone.find_by(easy_pages_id: page.id, easy_page_zones_id: zone.id)
    modul           = EasyPageModule.find_by(type: 'EpmActivityFeed')
    available_modul = EasyPageAvailableModule.find_by(easy_pages_id: page.id, easy_page_modules_id: modul.id)
    EasyPageZoneModule.create!(
        easy_pages_id:                  page.id,
        easy_page_available_zones_id:   available_zone.id,
        easy_page_available_modules_id: available_modul.id,
        entity_id:                      project.id,
        settings:                       { activity_scope: ['all'], projects: [''] }
    ) }

  describe 'show_selected_event_type' do
    render_views

    it 'get' do
      detail
      get :show_selected_event_type, :params => { event_type_id: 'all', module_id: page_module.id, format: 'js' }, :xhr => true
      expect(response).to be_successful
    end
  end

end
