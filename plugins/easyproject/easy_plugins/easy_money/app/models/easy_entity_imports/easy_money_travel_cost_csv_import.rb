module EasyEntityImports
  class EasyMoneyTravelCostCsvImport < EasyEntityCsvImport

    include ::EasyEntityImports::EasyMoneyBaseModelCsvImport

    def required_columns
      %w(easy_external_id entity_type entity_id price1 spent_on name project_id price_per_unit metric_units easy_currency_code)
    end

  end
end
