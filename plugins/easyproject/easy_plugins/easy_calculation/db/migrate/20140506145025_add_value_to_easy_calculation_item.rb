class AddValueToEasyCalculationItem < ActiveRecord::Migration[4.2]
  def up
    add_column(:easy_calculation_items, :value, :decimal, { :null => true, :precision => 30, :scale => 2 })
  end

  def down
    remove_column(:easy_calculation_items, :value)
  end
end
