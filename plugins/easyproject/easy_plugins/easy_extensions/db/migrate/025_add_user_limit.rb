class AddUserLimit < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => "user_limit", :value => 0
  end

  def self.down
    EasySetting.where(:name => 'user_limit').destroy_all
  end
end
