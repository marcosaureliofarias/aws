class AddHoursSelectorToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create!(:name => 'timeentry_hours_selector', :value => 'textbox')
  end

  def self.down
    EasySetting.where(:name => 'timeentry_hours_selector').destroy_all
  end
end