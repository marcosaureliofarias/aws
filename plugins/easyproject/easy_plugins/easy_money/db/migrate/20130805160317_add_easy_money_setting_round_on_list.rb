class AddEasyMoneySettingRoundOnList < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.create :name => 'round_on_list', :project_id => nil, :value => '1'
  end

  def self.down
  end
end
