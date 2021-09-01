require_relative '../../../../easy_extensions/test/spec/spec_helper'

# shared examples

RSpec.shared_examples 'exporter object' do
  include_context 'shared context'

  describe '#build_archive' do
    before(:each) do
      mock_exporter_file_methods
    end

    it 'should export build archive.zip with data and metadata files' do
      exported_file = exporter.build_archive
      zip_file = Zip::File.open(exported_file)
      expect(zip_file.map(&:name)).to eq(%w(data.xml metadata.xml))
    end
  end

  describe '#prepare_files' do
    before(:each) do
      mock_exporter_file_methods
    end

    it 'should write data to data and metadata files' do
      exporter.prepare_files

      data_xml = Nokogiri::XML(File.read(data_xml_file)) { |config| config.noblanks }
      metadata_xml = Nokogiri::XML(File.read(metadata_xml_file)) { |config| config.noblanks }

      validate_presence_of_elements(data_xml, expected_exported_elements)
      validate_presence_of_elements(metadata_xml, %w(entity-type name))
    end
  end

end

# shared context

RSpec.shared_context 'shared context', shared_context: :metadata do
  let(:metadata_xml_file) { Tempfile.new(['metadata', '.xml']) }
  let(:data_xml_file) { Tempfile.new(['data', '.xml']) }
  let(:archive_file) { Tempfile.new(['archive', '.zip']) }

  def mock_exporter_file_methods
    allow(exporter).to receive(:metadata_xml_file_path).and_return(metadata_xml_file.path)
    allow(exporter).to receive(:data_xml_file_path).and_return(data_xml_file.path)
    allow(exporter).to receive(:archive_file_path).and_return(archive_file.path)
    allow(exporter).to receive(:clear_files)
  end

  def validate_presence_of_elements(xml, expected_elements)
    if expected_elements.is_a? Array
      exported_elements = []
      expected_elements.each do |element|
        exported_elements << element if xml.xpath("//#{element}").children.any?
      end
      expect(exported_elements).to match_array(expected_elements)
    elsif expected_elements.is_a? Hash
      exported_elements = {}
      expected_elements.keys.each do |element|
        exported_elements[element] = xml.xpath("//#{element}").count
      end
      expect(exported_elements).to eq(expected_elements)
    end
  end

end
