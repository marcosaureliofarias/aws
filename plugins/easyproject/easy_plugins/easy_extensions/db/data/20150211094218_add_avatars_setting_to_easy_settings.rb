class AddAvatarsSettingToEasySettings < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'show_avatars_on_query', value: true)
  end

  def down
    EasySetting.where(:name => 'show_avatars_on_query').destroy_all
  end
end
