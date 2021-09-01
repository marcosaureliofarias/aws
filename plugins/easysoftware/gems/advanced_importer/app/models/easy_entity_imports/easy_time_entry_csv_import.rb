module EasyEntityImports
  class EasyTimeEntryCsvImport < EasyEntityCsvImport

    def entity_type
      'TimeEntry'
    end

    def get_available_entity_types
      []
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new

      %w(easy_external_id project_id issue_id spent_on user_id hours activity_id).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: true)
      end

      %w(comments easy_is_billable).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col)
      end

      @assignable_entity_columns
    end

  end
end
