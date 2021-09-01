class AddUserPreferencesTimEntrySettingDefaultValue < ActiveRecord::Migration[4.2]
  def self.up
    UserPreference.where('user_time_entry_setting = \'\' OR user_time_entry_setting IS NULL').update_all(user_time_entry_setting: 'hours')

    change_column :user_preferences, :user_time_entry_setting, :string, { :null => false, :default => 'hours' }
  end

  def self.down
    change_column :user_preferences, :user_time_entry_setting, :string, :null => true
  end
end
