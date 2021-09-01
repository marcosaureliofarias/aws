class AddIndexToEasyCurrencyExchangeRates < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_currency_exchange_rates, [:base_code, :to_code], :name => 'idx_easy_exch_rates'
  end

  def self.down
    remove_index :easy_currency_exchange_rates, :name => 'idx_easy_exch_rates'
  end
end
