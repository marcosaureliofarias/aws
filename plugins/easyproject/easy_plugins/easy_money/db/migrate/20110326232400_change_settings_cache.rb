class ChangeSettingsCache < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.where(name: 'cache').update_all(value: 'daily')
  end

  def self.down
  end

end
