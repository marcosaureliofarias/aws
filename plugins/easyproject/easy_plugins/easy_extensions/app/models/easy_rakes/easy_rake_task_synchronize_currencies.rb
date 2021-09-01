class EasyRakeTaskSynchronizeCurrencies < EasyRakeTask

  def execute
    rates = EasyCurrency.synchronize_exchange_rates(Date.today, EasyExtensions::ApiServicesForExchangeRates::RatesEasysoftwareCom)


    [rates.present?, rates]
  end

end
