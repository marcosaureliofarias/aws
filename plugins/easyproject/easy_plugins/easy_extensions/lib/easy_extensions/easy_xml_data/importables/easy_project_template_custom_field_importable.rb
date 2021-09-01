require 'easy_extensions/easy_xml_data/importables/custom_field_importable'

module EasyXmlData
  class EasyProjectTemplateCustomFieldImportable < CustomFieldImportable

    def initialize(data)
      @klass = EasyProjectTemplateCustomField
      super
    end

    private

    def import_record(xml, map)
      record                               = super
      from_id                              = xml.xpath('id').text
      map['project_custom_field']          ||= {}
      map['project_custom_field'][from_id] = map['easy_project_template_custom_field'][from_id]
      record
    end

  end
end
