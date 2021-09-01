class AddTimestampsToEasyCurrencies < ActiveRecord::Migration[5.2]

  def up
    add_timestamps :easy_currencies, null: true
    EasyCurrency.reset_column_information
    EasyCurrency.update_all(created_at: Time.now, updated_at: Time.now)
    change_column_null(:easy_currencies, :created_at, false)
    change_column_null(:easy_currencies, :updated_at, false)
  end

  def down
    remove_timestamps :easy_currencies
  end

end
