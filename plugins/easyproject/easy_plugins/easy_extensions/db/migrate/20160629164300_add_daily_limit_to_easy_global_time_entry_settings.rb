class AddDailyLimitToEasyGlobalTimeEntrySettings < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_global_time_entry_settings, :time_entry_daily_limit, :integer, null: true
  end

  def down
    remove_column :easy_global_time_entry_settings, :time_entry_daily_limit
  end
end
