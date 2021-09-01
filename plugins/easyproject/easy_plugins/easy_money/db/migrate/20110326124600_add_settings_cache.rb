class AddSettingsCache < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.create :name => 'cache', :project_id => nil, :value => 'hit'
  end

  def self.down
  end

end
