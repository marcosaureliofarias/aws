class DropCurrencyColumnsFromEasyMoneyUserRates < EasyExtensions::EasyDataMigration
  def up
    columns_to_remove = EasyMoneyRate.column_names.select{|c| c.match(/unit_rate_\D{3}/)}

    ActiveRecord::Migration.change_table(EasyMoneyRate.table_name) do |table|
      columns_to_remove.each do |column_name|
        table.remove column_name
      end
    end
  end

  def down
  end
end
