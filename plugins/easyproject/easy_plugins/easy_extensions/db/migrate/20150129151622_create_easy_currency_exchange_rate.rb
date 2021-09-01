class CreateEasyCurrencyExchangeRate < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_currency_exchange_rates do |t|
      t.decimal :rate, scale: 6, precision: 18, default: 1.0, null: false
      t.integer :base_id, null: false
      t.integer :to_id, null: false
    end
  end

  def self.down
    drop_table :easy_currency_exchange_rates
  end
end