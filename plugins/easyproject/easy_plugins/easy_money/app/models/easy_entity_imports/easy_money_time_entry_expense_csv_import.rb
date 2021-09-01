module EasyEntityImports
  class EasyMoneyTravelExpenseCsvImport < EasyEntityCsvImport

    include ::EasyEntityImports::EasyMoneyBaseModelCsvImport

    def required_columns
      %w(time_entry_id rate_type_id price)
    end

    def optional_columns
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
        entity = EasyMoneyTimeEntryExpense.new

        assign_entity_attributes(entity, attributes)

        e = build_imported_entity(iid, entity, line, attributes)
        begin
          e.entity.save(validate: false)
          after_save_callback(e.entity, line, attributes)
        rescue StandardError => ex
          raise ex
        end
        @imported_entities[iid] = e
        logger.warn "* Importer CSV [EasyMoneyTimeEntryExpense]: #{e.entity.time_entry_id} => #{e.entity.id} (#{e.errors.full_messages.join(', ')})"
      end

      @imported_entities
    end

  end
end
