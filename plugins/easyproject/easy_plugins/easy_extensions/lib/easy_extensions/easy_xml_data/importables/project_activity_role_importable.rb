require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class ProjectActivityRoleImportable < Importable

    def initialize(data)
      @klass = ProjectActivityRole
      super
      @belongs_to_associations['activity_id'] = 'time_entry_activity'
    end

    def mappable?
      false
    end

    def import(map, skip_associations)
      EasySetting.value('enable_activity_roles') ? super(map, skip_associations) : map[id] ||= {}
    end

    private

    def import_record(xml, map)
      ep "importing #{klass.name}#N/A"
      record = create_record(xml, map)
      if record.blank? || record.new_record?
        ep 'import failed'
      else
        ep "imported as #{record.class.name}#N/A"
      end
      record
    end

    def before_record_save(record, xml, map)
      ProjectActivityRole.where(:project_id => record.project_id, :activity_id => record.activity_id, :role_id => record.role_id).blank?
    end

  end
end
