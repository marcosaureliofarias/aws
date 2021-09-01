require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageImportable < Importable
    def initialize(data)
      @klass = EasyPage
      super
    end

    def mappable?
      true
    end

    def entities_for_mapping
      pages = []
      @xml.xpath('//easy_xml_data/easy-pages/*').each do |page_xml|
        identifier        = page_xml.xpath('identifier').text
        user_defined_name = page_xml.xpath('user-defined-name').text
        match             = EasyPage.find_by(identifier: identifier)
        pages << { id: page_xml.xpath('id').text, identifier: identifier, user_defined_name: user_defined_name, match: match ? match.id : '' }
      end
      pages
    end

    private

    def update_attribute(page, name, value, map, xml)
      case name
      when 'identifier'
        value = map['easy_page']['identifier']
        value = value.to_s.tr(' ', '_')
        while EasyPage.exists?(identifier: value)
          number = (value.match(/\d+$/) || [])[0]
          value << '1' unless number
          value.succ!
        end
      when 'user_defined_name'
        value = map['easy_page']['user_defined_name'] if map['easy_page']
      end
      super
    end

    def after_record_save(page, xml, map)
      page.install_registered_modules
    end

    def handle_record_error(record)
      raise EasyXmlData::Importer::CancelImportException, 'fatal import error, imported entity could not be saved, import cannot continue'
    end

  end
end
