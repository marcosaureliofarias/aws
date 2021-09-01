module EasyEntityImports
  module EasyMoneyBaseModelCsvImport

    def entity_type
      self.class.name.demodulize.chomp('CsvImport')
    end

    def get_available_entity_types
      []
    end

    def required_columns
      %w(easy_external_id entity_type entity_id price1 price2 vat spent_on name project_id easy_currency_code)
    end

    def optional_columns
      %w(id description tag_list)
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = ::EasyEntityImport::AvailableColumns.new

      required_columns.each do |col|
        @assignable_entity_columns << ::EasyEntityImport::EasyEntityImportAttribute.new(col, required: true)
      end

      optional_columns.each do |col|
        @assignable_entity_columns << ::EasyEntityImport::EasyEntityImportAttribute.new(col)
      end

      custom_field_class.find_each do |cf|
        @assignable_entity_columns << ::EasyEntityImport::EasyEntityImportAttribute.new("cf_#{cf.id}", required: cf.is_required?, title: cf.translated_name)
      end if custom_field_class

      @assignable_entity_columns
    end

    def assign_entity_attributes(entity, attributes)
      (required_columns + optional_columns).each do |col|
        if entity.respond_to?(col_writer = col + '=')
          entity.send(col_writer, attributes[col])
        end
      end
    end

    private

    def custom_field_class
      begin
        (entity_type + 'CustomField').constantize
      rescue NameError => e
        nil
      end
    end

  end
end
