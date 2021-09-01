class AddDateToEasyCurrencyExchangeRate < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_currency_exchange_rates, :valid_on, :date, { :null => true }
  end
end
