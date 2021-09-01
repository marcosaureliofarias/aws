class RemoveCacheFromEasyMoneySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.where(:name => 'cache').destroy_all
  end

  def self.down
  end
end