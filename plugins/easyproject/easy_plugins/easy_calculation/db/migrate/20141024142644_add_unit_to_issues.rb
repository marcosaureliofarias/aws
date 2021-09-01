class AddUnitToIssues < ActiveRecord::Migration[4.2]
  def up
    add_column(:issues, :calculation_unit, :string)
  end

  def down
    remove_column(:issues, :calculation_unit)
  end
end
