class AddDateColumnsToMoney < ActiveRecord::Migration[4.2]
  def self.up

    [:easy_money_expected_expenses, :easy_money_expected_revenues, :easy_money_other_expenses, :easy_money_other_revenues].each do |tbl|

      add_column(tbl, :tyear, :integer, {:null => true}) unless column_exists?(tbl, :tyear)
      add_column(tbl, :tmonth, :integer, {:null => true}) unless column_exists?(tbl, :tmonth)
      add_column(tbl, :tweek, :integer, {:null => true}) unless column_exists?(tbl, :tweek)
      add_column(tbl, :tday, :integer, {:null => true}) unless column_exists?(tbl, :tday)

    end

    EasyMoneyExpectedExpense.reset_column_information
    EasyMoneyExpectedRevenue.reset_column_information
    EasyMoneyOtherExpense.reset_column_information
    EasyMoneyOtherRevenue.reset_column_information

  end

  def self.down

    [:easy_money_expected_expenses, :easy_money_expected_revenues, :easy_money_other_expenses, :easy_money_other_revenues].each do |tbl|

      remove_column tbl, :tyear
      remove_column tbl, :tmonth
      remove_column tbl, :tweek
      remove_column tbl, :tday

    end

  end
end
