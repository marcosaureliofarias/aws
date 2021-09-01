require_relative './shared_stuff.rb'

RSpec.describe EasyXmlData::EasyPageExporter, type: :model do
  let(:easy_page) { FactoryGirl.create(:easy_page) }
  let(:easy_page_user_tab) do
    tab = EasyPageUserTab.create(name: 'untranslated_name', page_id: easy_page.id)
    tab.easy_translated_name = { cs: 'Translated name CS', en: 'Translated name EN' }
    tab.save
    tab
  end
  let!(:page_module) { FactoryGirl.create :easy_page_zone_module, easy_pages_id: easy_page.id, tab_id: easy_page_user_tab.id }
  let(:exporter) { EasyXmlData::EasyPageExporter.new(easy_page.id) }

  it_behaves_like 'exporter object' do
    let(:expected_exported_elements) do
      {
        'easy-pages/easy-page' => 1,
        'easy-page-zone-modules/easy-page-zone-module' => 1,
        'easy-page-user-tabs/easy-page-user-tab' => 1,
        'easy-translations/easy-translation' => 2,
      }
    end
  end
end
