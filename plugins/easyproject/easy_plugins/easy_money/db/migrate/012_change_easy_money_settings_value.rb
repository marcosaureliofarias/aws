class ChangeEasyMoneySettingsValue < ActiveRecord::Migration[4.2]
  def self.up
    change_column :easy_money_settings, "value", :string, { :null => true, :limit => 255 }
  end

  def self.down
  end
end
