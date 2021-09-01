class AddCalculationRateToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :calculation_rate, :decimal, :precision => 30, :scale => 2
  end

  def self.down
    remove_column :issues, :calculation_rate
  end
end
