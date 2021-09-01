RSpec.describe EasyXmlData::Importer do

  subject { described_class.new }

  let(:map) do
    {
      'user' => { '173' => '', '2115' => '' },
      'easy_printable_template' => { '16' => '' }
    }
  end

  context 'easy printable template' do
    it '#import' do
      allow(subject).to receive(:clear_import_dir)
      allow(subject).to receive(:import_dir).and_return(File.join(__dir__, "../fixtures/files"))
      map.each do |entity_type, map|
        subject.add_map(map, entity_type)
      end
      subject.import

      expect(EasyPrintableTemplate.exists?(name: 'template test', description: 'template description')).to be true
      expect(EasyPrintableTemplatePage.exists?(page_text: 'test template page'))

      FileUtils.rm_r(File.join(__dir__, "../fixtures/files/data.xml"))
    end
  end
end
