class AddMarginProfitToToProjectCaches < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_project_caches, :profit_margin, :float, { :null => false, :default => 0.0 }
  end

  def self.down
    remove_column :easy_money_project_caches, :profit_margin
  end
end