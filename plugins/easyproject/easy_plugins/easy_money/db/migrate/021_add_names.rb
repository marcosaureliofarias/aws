class AddNames < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_money_expected_expenses, :name, :string, { :null => false, :limit => 255 }
    add_column :easy_money_expected_revenues, :name, :string, { :null => false, :limit => 255 }
  end

  def self.down
  end
end
