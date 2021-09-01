class AddProjectIdToEasyMoney < ActiveRecord::Migration[4.2]

  EASY_MONEY_TABLE_NAMES = [:easy_money_expected_revenues, :easy_money_expected_expenses,
    :easy_money_other_revenues, :easy_money_other_expenses, :easy_money_expected_payroll_expenses]
  EASY_MONEY_MODELS = EASY_MONEY_TABLE_NAMES.map{|t| t.to_s.classify.constantize}

  def up
    EASY_MONEY_TABLE_NAMES.each do |table_name|
      add_column table_name, :project_id, :integer, {:null => true}
    end
    EASY_MONEY_MODELS.each {|m| m.reset_column_information}
  end

  def down
    EASY_MONEY_TABLE_NAMES.each do |table_name|
      remove_column table_name, :project_id
    end
    EASY_MONEY_MODELS.each {|m| m.reset_column_information}
  end
end
