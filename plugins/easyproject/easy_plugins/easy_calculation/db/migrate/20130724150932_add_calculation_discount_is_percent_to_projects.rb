class AddCalculationDiscountIsPercentToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :calculation_discount_is_percent, :boolean, :null => false, :default => false
  end
end
