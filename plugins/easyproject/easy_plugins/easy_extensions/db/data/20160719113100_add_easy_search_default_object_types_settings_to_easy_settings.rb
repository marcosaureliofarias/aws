class AddEasySearchDefaultObjectTypesSettingsToEasySettings < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'easy_search_default_object_types', value: ['issues'])
  end

  def down
    EasySetting.where(:name => 'easy_search_default_object_types').destroy_all
  end
end
