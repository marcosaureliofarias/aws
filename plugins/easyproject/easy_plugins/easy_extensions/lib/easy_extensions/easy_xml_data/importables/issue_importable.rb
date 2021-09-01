require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssueImportable < Importable

    def initialize(data)
      @klass = Issue
      super
    end

    def mappable?
      false
    end

    def update_attribute(record, name, value, map, xml)
      case name
      when 'project_id'
        record.project_id = map['project'] ? map['project'][value] : value
      when 'parent_id'
        if value.present? && map['issue'] && map['issue'][value]
          record.parent_id = map['issue'][value]
        end
      else
        super
      end
    end

    def updatable_attribute?(attr_name)
      attr_name == 'parent_id' || super
    end

    def validate?
      false
    end

    def before_record_save(record, xml, map)
      # we shouldn't save issue without activity
      # but otherwise we just lose this data
      if record.activity.blank?
        ep "no activity assigned, so we do the best guess"
        record.activity = record.project.time_entry_activities.default || record.project.time_entry_activities.first || TimeEntryActivity.default || TimeEntryActivity.first
      end
      if original_id_custom_field_id.present?
        ep "saving original id of #{xml.xpath('id').text} into custom field ##{original_id_custom_field_id}"
        record.custom_field_values = { original_id_custom_field_id.to_s => xml.xpath('id').text }
      end
      true
    end

    def original_id_custom_field_id
      ENV['EASY_IMPORTER_ISSUE_ORIGINAL_ID_CUSTOM_FIELD_ID']
    end

  end
end
