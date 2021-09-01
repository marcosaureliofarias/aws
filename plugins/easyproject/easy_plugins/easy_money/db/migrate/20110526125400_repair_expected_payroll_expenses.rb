class RepairExpectedPayrollExpenses < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.where("name = 'expected_payroll_expense' AND value IS NULL").update_all(value: 1)
  end

  def self.down
  end

end
