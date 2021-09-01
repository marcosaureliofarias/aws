class AddUnitToEasyCalculationItem < ActiveRecord::Migration[4.2]
  def up
    add_column(:easy_calculation_items, :unit, :string)
  end

  def down
    remove_column(:easy_calculation_items, :unit)
  end
end
