class AddDescriptions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_expected_expenses, :description, :text, { :null => true }
    add_column :easy_money_expected_revenues, :description, :text, { :null => true }
  end

  def self.down
  end
end
