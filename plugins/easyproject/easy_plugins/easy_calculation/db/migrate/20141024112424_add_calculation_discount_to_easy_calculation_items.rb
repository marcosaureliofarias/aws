class AddCalculationDiscountToEasyCalculationItems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_calculation_items, :calculation_discount, :integer
    add_column :easy_calculation_items, :calculation_discount_is_percent, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :easy_calculation_items, :calculation_discount
    remove_column :easy_calculation_items, :calculation_discount_is_percent
  end
end
