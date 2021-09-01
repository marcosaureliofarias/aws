class AddCarddavEnabledToEasySettings < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'easy_carddav_enabled', value: true)
  end

  def down
    EasySetting.where(name: 'easy_carddav_enabled').destroy_all
  end
end
