class AddEasyMoneySettingCurrencyVisible < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.create(:name => 'currency_visible', :value => nil)
  end

  def self.down
  end
end