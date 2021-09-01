require 'easy_extensions/easy_xml_data/importables/custom_field_importable'

module EasyXmlData
  class IssueCustomFieldImportable < CustomFieldImportable

    def initialize(data)
      @klass = IssueCustomField
      super
    end

    private

    def before_record_save(record, _xml, _map)
      record.visible = true unless record.visible? || record.roles.present?
    end

    def update_attribute(record, name, value, map, xml)
      case name
      when 'format_store'
        hash_attribute = Hash.new
        xml.children.select { |c| !c.text? }.map { |c| hash_attribute[c.name.underscore] = c.text }
        record.send("#{name}=", hash_attribute)
      else
        super
      end
    end

  end
end
