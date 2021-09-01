require_relative './shared_stuff.rb'

RSpec.describe EasyXmlData::EasyPageTemplateExporter, type: :model do
  let(:easy_page_template) { EasyPageTemplate.first }
  let!(:easy_page_template_tab) do
    tab = EasyPageTemplateTab.create(name: 'untranslated_name', page_template_id: easy_page_template.id)
    tab.easy_translated_name = { cs: 'Translated name CS', en: 'Translated name EN' }
    tab.save
    tab
  end
  let(:exporter) { EasyXmlData::EasyPageTemplateExporter.new(easy_page_template.id) }

  it_behaves_like 'exporter object' do
    let(:expected_exported_elements) do
      {
        'easy-page-templates/easy-page-template' => 1,
        'easy-page-template-tabs/easy-page-template-tab' => 1,
        'easy-translations/easy-translation' => 2,
      }
    end
  end
end
