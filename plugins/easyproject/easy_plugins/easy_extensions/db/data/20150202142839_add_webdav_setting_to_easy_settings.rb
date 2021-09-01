class AddWebdavSettingToEasySettings < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create!(name: 'easy_webdav_enabled', value: true)
  end

  def self.down
    EasySetting.where(:name => 'easy_webdav_enabled').destroy_all
  end
end
