class AddUserPreferencesTimeEntrySetting < ActiveRecord::Migration[4.2]
  def self.up
    add_column :user_preferences, :user_time_entry_setting, :string, :null => true
  end

  def self.down
    remove_column :user_preferences, :user_time_entry_setting
  end
end
