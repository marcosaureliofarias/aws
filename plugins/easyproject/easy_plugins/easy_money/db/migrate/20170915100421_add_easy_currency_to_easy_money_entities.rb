class AddEasyCurrencyToEasyMoneyEntities < ActiveRecord::Migration[4.2]
  def currency_tables
    [:easy_money_rates, :easy_money_expected_expenses, :easy_money_expected_revenues, :easy_money_other_expenses,
      :easy_money_other_revenues, :easy_money_travel_costs, :easy_money_travel_expenses, :easy_money_expected_payroll_expenses,
      :easy_money_periodical_entity_items, :easy_money_project_caches]
  end

  def up
    add_column :easy_money_rates, :updated_at, :timestamp
    add_column :easy_money_expected_payroll_expenses, :updated_at, :timestamp

    currency_tables.each do |tbl|
      add_column tbl, :easy_currency_code, :string, limit: 3
    end

    add_index :easy_money_project_caches, [:project_id, :easy_currency_code], unique: true, name: 'index_empc_on_project_id_and_easy_currency_code'
    remove_index :easy_money_project_caches, :project_id
  end

  def down
    remove_column :easy_money_rates, :updated_at
    remove_column :easy_money_expected_payroll_expenses, :updated_at

    remove_index :easy_money_project_caches, name: 'index_empc_on_project_id_and_easy_currency_code'

    currency_tables.each do |tbl|
      remove_column tbl, :easy_currency_code
    end
  end
end
