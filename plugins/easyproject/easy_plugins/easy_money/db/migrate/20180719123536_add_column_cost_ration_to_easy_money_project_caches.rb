class AddColumnCostRationToEasyMoneyProjectCaches < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_money_project_caches, :cost_ratio, :float, { null: false, default: 0.0 }
  end
end
