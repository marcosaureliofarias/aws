module EasyEntityImports
  class EasyJournalCsvImport < EasyEntityCsvImport

    class AvailableColumns < AvailableColumns
      def unwanted_column_names
        super - ['created_on']
      end
    end

    def entity_type
      'Journal'
    end

    def get_available_entity_types
      []
    end
  
    def import(file)
      set_variables unless @variables_sets
      CSV.new(file, headers: true).each_with_index do |line, index|
        iid = "#{Date.today.strftime('%Y%m%d')}#{'%05d' % index}"
        attributes = { 'custom_fields' => [] }
        easy_entity_import_attributes_assignments.each do |att|
          value = att.is_custom? && att.value.presence || (line[att.source_attribute.to_i].try(:strip) || att.default_value)
          attributes = ensure_attribute_value(attributes, att, value.presence)
        end
        entity = Journal.new

        assign_entity_attributes(entity, attributes)

        e = build_imported_entity(iid, entity, line, attributes)
        begin
          e.entity.save(validate: false)
          after_save_callback(e.entity, line, attributes)
        rescue StandardError => ex
          raise ex
        end
        @imported_entities[iid] = e
        logger.warn "* Importer CSV [Journal]: #{e.entity.journalized_type}##{e.entity.journalized_id} => #{e.entity.id} (#{e.errors.full_messages.join(', ')})"
      end

      @imported_entities
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new

      %w(journalized_id journalized_type user_id notes created_on).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: true)
      end

      %w(private_notes).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col)
      end

      @assignable_entity_columns
    end

    def assign_entity_attributes(entity, attributes)
      entity.journalized_id   = attributes['journalized_id']
      entity.journalized_type = attributes['journalized_type']
      entity.user_id          = attributes['user_id']
      entity.notes            = attributes['notes']
      entity.created_on       = attributes['created_on']
      entity.private_notes    = attributes['private_notes'].present?
    end

  end
end
