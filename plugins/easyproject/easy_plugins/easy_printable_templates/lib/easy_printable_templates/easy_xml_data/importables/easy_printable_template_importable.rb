require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPrintableTemplateImportable < Importable
    def initialize(data)
      @klass = EasyPrintableTemplate
      super
    end

    def mappable?
      true
    end

    def entities_for_mapping
      templates = []
      @xml.xpath('//easy_xml_data/easy-printable-templates/*').each do |template_xml|
        template_name = template_xml.xpath('name').text
        description = template_xml.xpath('description').text
        templates << { id: template_xml.xpath('id').text, template_name: template_name, description: description }
      end
      templates
    end

  end
end
