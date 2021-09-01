require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPrintableTemplatePageImportable < Importable
    def initialize(data)
      @klass = EasyPrintableTemplatePage
      super
    end

    def mappable?
      false
    end

    def update_attribute(page, name, value, map, xml)
      if name == 'easy_printable_template_id'
        return unless value.present?
        page.easy_printable_template_id = map['easy_printable_template'][value]
      else
        super
      end
    end

  end
end
