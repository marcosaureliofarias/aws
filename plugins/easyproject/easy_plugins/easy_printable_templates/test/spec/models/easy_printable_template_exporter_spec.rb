require File.join(EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_data_templates/test/spec/models/shared_stuff.rb')

RSpec.describe EasyXmlData::EasyPrintableTemplateExporter, type: :model do
  let(:easy_printable_template) { FactoryBot.create(:easy_printable_template, :with_easy_printable_template_pages) }
  let(:exporter) { EasyXmlData::EasyPrintableTemplateExporter.new(easy_printable_template.id) }

  it_behaves_like 'exporter object' do
    let(:expected_exported_elements) { %w(easy-printable-template pages-orientation easy-printable-template-page page-text) }
  end
end
