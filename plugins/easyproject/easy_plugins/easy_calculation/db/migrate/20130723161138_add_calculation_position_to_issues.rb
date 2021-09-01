class AddCalculationPositionToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :calculation_position, :integer
  end

  def self.down
    remove_column :issues, :calculation_position
  end
end
