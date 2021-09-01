class AddTravelPricesToProjectCaches < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_project_caches, :sum_of_all_travel_costs_price_1, :float, { :null => false, :default => 0.0 }
    add_column :easy_money_project_caches, :sum_of_all_travel_expenses_price_1, :float, { :null => false, :default => 0.0 }
  end

  def self.down
    remove_column :easy_money_project_caches, :sum_of_all_travel_costs_price_1
    remove_column :easy_money_project_caches, :sum_of_all_travel_expenses_price_1
  end
end
