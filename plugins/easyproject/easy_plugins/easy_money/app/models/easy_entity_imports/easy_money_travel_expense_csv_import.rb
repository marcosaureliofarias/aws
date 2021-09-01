module EasyEntityImports
  class EasyMoneyTravelExpenseCsvImport < EasyEntityCsvImport

    include ::EasyEntityImports::EasyMoneyBaseModelCsvImport

    def required_columns
      %w(easy_external_id entity_type entity_id price1 spent_on name project_id user_id spent_on_to price_per_day easy_currency_code)
    end

  end
end
