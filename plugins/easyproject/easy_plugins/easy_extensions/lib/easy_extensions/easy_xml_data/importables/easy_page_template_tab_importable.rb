require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageTemplateTabImportable < Importable
    def initialize(data)
      @klass = EasyPageTemplateTab
      super
    end

    def mappable?
      false
    end

    def entities_for_mapping
      pages = []
      @xml.xpath('//easy_xml_data/easy-page-template-tabs/*').each do |page_xml|
        name = page_xml.xpath('name').text
        pages << { id: page_xml.xpath('id').text, name: name }
      end
      pages
    end

    private

    def update_attribute(page, name, value, map, xml)
      value = map['easy_page_template'][value] if name == 'page_template_id'
      super
    end

  end
end
