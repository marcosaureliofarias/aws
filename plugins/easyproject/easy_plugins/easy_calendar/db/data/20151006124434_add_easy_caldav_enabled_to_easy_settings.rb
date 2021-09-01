class AddEasyCaldavEnabledToEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create!(name: 'easy_caldav_enabled', value: true)
  end

  def down
    EasySetting.where(name: 'easy_caldav_enabled').destroy_all
  end
end
