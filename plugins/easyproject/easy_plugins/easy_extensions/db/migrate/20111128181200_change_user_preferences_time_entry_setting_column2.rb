class ChangeUserPreferencesTimeEntrySettingColumn2 < ActiveRecord::Migration[4.2]
  def self.up
    UserPreference.where('user_time_entry_setting = \'\' OR user_time_entry_setting IS NULL').update_all(user_time_entry_setting: 'hours')
  end

  def self.down
  end
end
