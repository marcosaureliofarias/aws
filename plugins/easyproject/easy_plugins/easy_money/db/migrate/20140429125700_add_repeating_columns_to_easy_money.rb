class AddRepeatingColumnsToEasyMoney < ActiveRecord::Migration[4.2]

  EASY_MONEY_TABLE_NAMES = [:easy_money_expected_revenues, :easy_money_expected_expenses, :easy_money_other_revenues, :easy_money_other_expenses]
  EASY_MONEY_MODELS = EASY_MONEY_TABLE_NAMES.map{|t| t.to_s.classify.constantize}

  def up
    EASY_MONEY_TABLE_NAMES.each do |table_name|
      add_column(table_name, :easy_repeat_settings, :text, limit: 999.megabyte, default: nil) unless(column_exists? table_name, :easy_repeat_settings)
      add_column(table_name, :easy_is_repeating, :boolean) unless column_exists?(table_name, :easy_is_repeating)
      add_column(table_name, :easy_next_start, :date) unless column_exists?(table_name, :easy_next_start)
    end
    EASY_MONEY_MODELS.each {|m| m.reset_column_information}
  end

  def down
    EASY_MONEY_TABLE_NAMES.each do |table_name|
      remove_column(table_name, :easy_repeat_settings) if column_exists?(table_name, :easy_repeat_settings)
      remove_column(table_name, :easy_is_repeating) if column_exists?(table_name, :easy_is_repeating)
      remove_column(table_name, :easy_next_start) if column_exists?(table_name, :easy_next_start)
    end
    EASY_MONEY_MODELS.each {|m| m.reset_column_information}
  end
end
