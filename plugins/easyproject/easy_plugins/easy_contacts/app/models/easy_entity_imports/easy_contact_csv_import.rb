module EasyEntityImports
  class EasyContactCsvImport < EasyEntityCsvImport

    def entity_type
      'EasyContact'
    end

    def get_available_entity_types
      []
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new

      %w(easy_external_id type_id firstname lastname).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: true)
      end

      %w(id assigned_to_id external_assigned_to_id author_id parent_id author_note is_global is_public private).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col)
      end

      EasyContactCustomField.find_each do |cf|
        @assignable_entity_columns << EasyEntityImportAttribute.new("cf_#{cf.id}", required: cf.is_required?, title: cf.translated_name)
      end

      @assignable_entity_columns
    end

    private

    def assign_attributes(entity, attributes)
      entity.type_id = attributes['type_id']
      super
    end

  end
end
