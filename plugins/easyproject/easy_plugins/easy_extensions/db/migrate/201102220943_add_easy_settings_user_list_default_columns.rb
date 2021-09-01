class AddEasySettingsUserListDefaultColumns < ActiveRecord::Migration[4.2]
  def self.up
  end

  def self.down
    EasySetting.where(:name => 'user_list_default_columns').destroy_all
  end
end
