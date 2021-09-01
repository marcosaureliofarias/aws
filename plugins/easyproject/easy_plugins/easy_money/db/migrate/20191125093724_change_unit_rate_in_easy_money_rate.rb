class ChangeUnitRateInEasyMoneyRate < ActiveRecord::Migration[5.2]
  def up
    change_column :easy_money_rates, :unit_rate, :decimal, scale: 4, precision: 30, default: '0.0', null: false
  end
end
