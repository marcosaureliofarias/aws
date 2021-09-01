class AddUserPreferencesHoursFormatSetting < ActiveRecord::Migration[4.2]
  def self.up
    add_column :user_preferences, :hours_format, :string, :null => true
  end

  def self.down
    remove_column :user_preferences, :hours_format
  end
end
