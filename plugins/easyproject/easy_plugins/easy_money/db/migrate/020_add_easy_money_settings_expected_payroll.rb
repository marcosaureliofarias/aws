class AddEasyMoneySettingsExpectedPayroll < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.create :name => 'expected_payroll_expense', :project_id => nil, :value => '1'
  end

  def self.down
  end
end
