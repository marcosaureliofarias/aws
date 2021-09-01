module EasyEntityImports
  class EasyUserCsvImport < EasyEntityCsvImport

    def entity_type
      'User'
    end

    def get_available_entity_types
      []
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new
      %w(easy_external_id login firstname lastname mail password password_confirmation).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: true)
      end
      UserCustomField.find_each do |cf|
        @assignable_entity_columns << EasyEntityImportAttribute.new("cf_#{cf.id}", required: cf.is_required?, title: cf.translated_name)
      end
      %w(id easy_working_time_calendar_id user_type_id).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col)
      end

      @assignable_entity_columns
    end

    private

    def build_imported_entity(external_id, new_entity, csv_line, current_attributes)
      e = super

      if (parent = @imported_entities[current_attributes['parent_id']])
        e.entity.parent_id = parent.entity.id
      end

      e
    end

    def after_save_callback(entity, csv_line, current_attributes)
      if !entity.new_record? && (calendar = EasyUserWorkingTimeCalendar.find_by(user_id: nil, id: current_attributes['easy_working_time_calendar_id']))
        calendar.assign_to_user(entity, false)
      end
    end

  end
end
