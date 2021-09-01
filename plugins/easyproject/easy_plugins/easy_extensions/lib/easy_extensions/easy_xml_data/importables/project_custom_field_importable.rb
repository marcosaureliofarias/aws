require 'easy_extensions/easy_xml_data/importables/custom_field_importable'

module EasyXmlData
  class ProjectCustomFieldImportable < CustomFieldImportable

    def initialize(data)
      @klass = ProjectCustomField
      super
    end

  end
end
