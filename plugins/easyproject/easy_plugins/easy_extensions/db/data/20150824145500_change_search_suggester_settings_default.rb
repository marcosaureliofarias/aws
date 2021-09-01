class ChangeSearchSuggesterSettingsDefault < EasyExtensions::EasyDataMigration
  def up
    current_types = (EasySetting.where(:name => 'easy_search_suggester').first || {})['entity_types']
    EasySetting.where(name: 'easy_search_suggester').update_all(value: { 'enabled' => '1', 'entity_types' => current_types })
  end

  def down
  end
end
