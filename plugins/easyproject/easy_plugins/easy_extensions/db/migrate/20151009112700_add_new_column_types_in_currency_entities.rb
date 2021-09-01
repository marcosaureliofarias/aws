class AddNewColumnTypesInCurrencyEntities < ActiveRecord::Migration[4.2]

  def up
    add_column(:easy_currency_exchange_rates, :base_code, :string, limit: 3, index: true) unless column_exists?(:easy_currency_exchange_rates, :base_code)
    add_column(:easy_currency_exchange_rates, :to_code, :string, limit: 3, index: true) unless column_exists?(:easy_currency_exchange_rates, :to_code)
    change_column :easy_currency_exchange_rates, :base_id, :integer, null: true
    change_column :easy_currency_exchange_rates, :to_id, :integer, null: true
    add_column :projects, :easy_currency_code, :string, limit: 3, index: true
    add_column :easy_queries, :easy_currency_code, :string, limit: 3, index: true
  end

  def down
    remove_column :projects, :easy_currency_code
    remove_column :easy_queries, :easy_currency_code
  end

end
