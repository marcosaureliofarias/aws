module EasyEntityImports
  class EasyMoneyExpectedPayrollExpenseCsvImport < EasyEntityCsvImport

    class AvailableColumns < AvailableColumns
      def unwanted_column_names
        super - ['updated_at']
      end
    end

    include ::EasyEntityImports::EasyMoneyBaseModelCsvImport

    def required_columns
      %w(easy_external_id entity_type entity_id price project_id updated_at easy_currency_code)
    end

    def optional_columns
      %w(id)
    end

  end
end
