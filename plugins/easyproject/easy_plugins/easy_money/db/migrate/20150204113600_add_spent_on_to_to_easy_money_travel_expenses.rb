class AddSpentOnToToEasyMoneyTravelExpenses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_travel_expenses, :spent_on_to, :date, { :null => true }
  end

  def self.down
    remove_column :easy_money_travel_expenses, :spent_on_to
  end
end
