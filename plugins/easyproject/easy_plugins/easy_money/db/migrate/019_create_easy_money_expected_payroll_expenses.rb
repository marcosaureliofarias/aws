class CreateEasyMoneyExpectedPayrollExpenses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_money_expected_payroll_expenses do |t|
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :price, :decimal, { :null => false, :precision => 30, :scale => 2, :default => 0.0 }
    end
  end

  def self.down
    drop_table :easy_money_expected_payroll_expenses
  end
end
