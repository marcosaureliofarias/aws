module EasyAgileBoard
  class Utils
    class << self
      def import_default_template(file)
        importer = EasyXmlData::Importer.new
        xml = Nokogiri::XML(File.read(file)) {|config| config.noblanks }
        importer.instance_variable_set(:@xml, xml)
        importer.send(:set_importables)
        importer.auto_mapping_ids = []
        importer.auto_mapping
        importer.add_map({ 'template_name' => 'Default template', 'description' => 'default agile dashboard template', 'is_default' => true }, 'easy_page_template')
        importer.import
      end
    end
  end
end
