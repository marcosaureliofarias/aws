class AddValidOnIdxToEasyCurrencyExchangeRates < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_currency_exchange_rates, [:valid_on, :base_code, :to_code], :name => 'idx_easy_exch_rates_valid_on'
  end

  def self.down
    remove_index :easy_currency_exchange_rates, :name => 'idx_easy_exch_rates_valid_on'
  end
end
