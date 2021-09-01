class AddUpdatedAtToCurrencyExchangeRates < ActiveRecord::Migration[4.2]
  def up
    add_timestamps :easy_currency_exchange_rates, default: Time.now
  end

  def down
  end
end
