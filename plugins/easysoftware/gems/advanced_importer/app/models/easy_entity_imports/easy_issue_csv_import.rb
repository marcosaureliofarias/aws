module EasyEntityImports
  class EasyIssueCsvImport < EasyEntityCsvImport

    def entity_type
      'Issue'
    end

    def get_available_entity_types
      []
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new
      @assignable_entity_columns << EasyEntityImportAttribute.new('easy_external_id', :required => true)
      Issue.safe_attributes.collect(&:first).flatten.uniq.each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: self.required_attribute?(required_column_names, col.to_s))
      end
      IssueCustomField.find_each do |cf|
        @assignable_entity_columns << EasyEntityImportAttribute.new("cf_#{cf.id}", required: cf.is_required?, title: cf.translated_name)
      end
      @assignable_entity_columns << EasyEntityImportAttribute.new('id')

      @assignable_entity_columns
    end

    def build_imported_entity(external_id, new_entity, csv_line, current_attributes)
      e = super

      if (parent = @imported_entities[current_attributes['parent_id']])
        e.entity.parent_id = parent.entity.id
      end

      e
    end

  end
end
