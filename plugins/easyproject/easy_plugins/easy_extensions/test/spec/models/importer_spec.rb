require 'easy_extensions/spec_helper'

RSpec.describe EasyXmlData::Importer, type: :model do
  let(:importer) { EasyXmlData::Importer.new }

  context 'Project import' do
    project_1_data_xml_file     = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_project_1/data.xml').to_s
    project_1_metadata_xml_file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_project_1/metadata.xml').to_s

    project_1_xml          = Nokogiri::XML(File.read(project_1_data_xml_file)) { |config| config.noblanks }
    project_1_metadata_xml = Nokogiri::XML(File.read(project_1_metadata_xml_file)) { |config| config.noblanks }

    before(:each) do
      init_importer(project_1_xml.dup, project_1_metadata_xml.dup)
    end

    describe '#set_importables' do
      it 'should set importables' do
        expected_importables = [EasyXmlData::UserImportable,
                                EasyXmlData::GroupImportable,
                                EasyXmlData::EasyProjectTemplateCustomFieldImportable,
                                EasyXmlData::IssueCustomFieldImportable,
                                EasyXmlData::IssueStatusImportable,
                                EasyXmlData::TrackerImportable,
                                EasyXmlData::ProjectImportable,
                                EasyXmlData::EasyPageZoneModuleImportable,
                                EasyXmlData::RoleImportable,
                                EasyXmlData::MemberImportable,
                                EasyXmlData::IssuePriorityImportable,
                                EasyXmlData::IssueImportable,
                                EasyXmlData::TimeEntryActivityImportable]
        expect(importer.instance_variable_get(:@importables).map(&:class)).to match_array(expected_importables)
      end
    end

    describe '#import' do
      before(:each) do
        allow(importer).to receive(:import_attachment_files)
        allow(importer).to receive(:clear_import_dir)
      end

      it 'should import project without errors' do
        validation_errors = importer.import.validation_errors
        expect(validation_errors).to be_empty
      end

      it 'should import at least one entity per importable' do
        importer.import
        importables = importer.instance_variable_get(:@importables)
        expect(importables.count).to eq(importables.select { |importable| importable.processed_entities.present? }.count)
      end

      it 'should import associated records if project invalid' do
        allow_any_instance_of(Project).to receive(:valid?).and_return(false)

        validation_errors = importer.import.validation_errors
        expect(validation_errors).to be_empty
      end
    end
  end

  context 'EasyPage import' do
    easy_page_1_data_xml_file     = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_easy_page_1/data.xml').to_s
    easy_page_1_metadata_xml_file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_easy_page_1/metadata.xml').to_s

    easy_page_1_xml          = Nokogiri::XML(File.read(easy_page_1_data_xml_file)) { |config| config.noblanks }
    easy_page_1_metadata_xml = Nokogiri::XML(File.read(easy_page_1_metadata_xml_file)) { |config| config.noblanks }

    before(:each) do
      init_importer(easy_page_1_xml.dup, easy_page_1_metadata_xml.dup, [])
    end

    describe '#set_importables' do
      it 'should set importables' do
        expected_importables = [EasyXmlData::EasyPageImportable, EasyXmlData::EasyPageZoneModuleImportable]
        expect(importer.instance_variable_get(:@importables).map(&:class)).to match_array(expected_importables)
      end
    end

    describe '#import' do
      before(:each) do
        allow(importer).to receive(:import_attachment_files)
        allow(importer).to receive(:clear_import_dir)
        importer.add_map({ 'user_defined_name' => 'Cusom Page', 'identifier' => 'cusom-page' }, 'easy_page')
      end

      it 'should import easy page without errors' do
        validation_errors = importer.import.validation_errors
        expect(validation_errors).to be_empty
      end

      it 'should import at least one entity per importable' do
        importer.import
        importables = importer.instance_variable_get(:@importables)
        expect(importables.count).to eq(importables.select { |importable| importable.processed_entities.present? }.count)
      end
    end
  end

  context 'EasyPageTemplate import' do
    easy_page_template_1_data_xml_file     = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_easy_page_template_1/data.xml').to_s
    easy_page_template_1_metadata_xml_file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_xml_data/exported_easy_page_template_1/metadata.xml').to_s

    easy_page_template_1_xml          = Nokogiri::XML(File.read(easy_page_template_1_data_xml_file)) { |config| config.noblanks }
    easy_page_template_1_metadata_xml = Nokogiri::XML(File.read(easy_page_template_1_metadata_xml_file)) { |config| config.noblanks }

    before(:each) do
      init_importer(easy_page_template_1_xml.dup, easy_page_template_1_metadata_xml.dup, [])
    end

    describe '#set_importables' do
      it 'should set importables' do
        expected_importables = [EasyXmlData::EasyPageTemplateImportable,
                                EasyXmlData::EasyPageTemplateTabImportable,
                                EasyXmlData::EasyPageTemplateModuleImportable]
        expect(importer.instance_variable_get(:@importables).map(&:class)).to match_array(expected_importables)
      end
    end

    describe '#import' do
      before(:each) do
        allow(importer).to receive(:import_attachment_files)
        allow(importer).to receive(:clear_import_dir)
        importer.add_map({ 'template_name' => 'Custom User Template', 'description' => 'custom user template description' }, 'easy_page_template')
      end

      it 'should import easy page without errors' do
        validation_errors = importer.import.validation_errors
        expect(validation_errors).to be_empty
      end

      it 'should import at least one entity per importable' do
        importer.import
        importables = importer.instance_variable_get(:@importables)
        expect(importables.count).to eq(importables.select { |importable| importable.processed_entities.present? }.count)
      end
    end
  end

  def init_importer(data_xml, metadata_xml, auto_mapping_ids = nil)
    importer.instance_variable_set(:@xml, data_xml)
    importer.instance_variable_set(:@metadata_xml, metadata_xml)
    importer.send(:set_importables)
    auto_mapping_ids          = auto_mapping_ids || %w(user group role tracker issue_priority issue_status project_custom_field easy_project_template_custom_field issue_custom_field document_category time_entry_activity)
    importer.auto_mapping_ids = auto_mapping_ids
    importer.auto_mapping
  end

end
