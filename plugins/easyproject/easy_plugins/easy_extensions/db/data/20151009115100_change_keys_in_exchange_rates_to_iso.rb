class ChangeKeysInExchangeRatesToIso < EasyExtensions::EasyDataMigration
  def up
    EasyCurrencyExchangeRate.reset_column_information
    mapping_array = EasyCurrency.pluck(:id, :iso_code)
    mapping_array.each do |currency|
      EasyCurrencyExchangeRate.where(base_id: currency[0].to_s).update_all(base_code: currency[1])
      EasyCurrencyExchangeRate.where(to_id: currency[0].to_s).update_all(to_code: currency[1])
      Project.where(easy_currency_id: currency[0].to_s).update_all(easy_currency_code: currency[1])
    end
  end

  def down
    EasyCurrencyExchangeRate.reset_column_information
    mapping_array = EasyCurrency.pluck(:iso_code, :id)
    mapping_array.each do |currency|
      EasyCurrencyExchangeRate.where(base_id: currency[0].to_s).update_all(base_id: currency[1])
      EasyCurrencyExchangeRate.where(to_id: currency[0].to_s).update_all(to_id: currency[1])
      Project.where(easy_currency_code: currency[0].to_s).update_all(easy_currency_id: currency[1])
    end
  end
end
