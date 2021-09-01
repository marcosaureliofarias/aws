class AddSearchSuggesterSettingsToEasySettings < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'easy_search_suggester', value: { 'enabled' => '0', 'entity_types' => ['issues'] })
  end

  def down
    EasySetting.where(:name => 'easy_search_suggester').destroy_all
  end
end
