class RemoveTcolsFromEasyMoneyTravelExpenses < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :easy_money_travel_expenses, :tyear
    remove_column :easy_money_travel_expenses, :tmonth
    remove_column :easy_money_travel_expenses, :tweek
    remove_column :easy_money_travel_expenses, :tday
  end

  def self.down
  end
end
