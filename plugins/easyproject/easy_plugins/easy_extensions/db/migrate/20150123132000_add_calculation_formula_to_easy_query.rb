class AddCalculationFormulaToEasyQuery < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_queries, :calculation_formula, :string, { :null => true, :limit => 255 }
  end
end
