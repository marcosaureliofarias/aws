class AddEasyAvatarToSettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => 'avatar_enabled', :value => true
  end

  def self.down
    EasySetting.where(:name => 'avatar_enabled').destroy_all
  end
end
