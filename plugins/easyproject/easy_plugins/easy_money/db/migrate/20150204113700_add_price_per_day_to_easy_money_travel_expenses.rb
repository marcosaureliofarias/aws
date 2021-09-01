class AddPricePerDayToEasyMoneyTravelExpenses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_travel_expenses, :price_per_day, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
  end

  def self.down
    remove_column :easy_money_travel_expenses, :price_per_day
  end
end
