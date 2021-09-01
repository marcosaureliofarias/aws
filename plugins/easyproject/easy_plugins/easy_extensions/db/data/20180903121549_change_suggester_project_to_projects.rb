class ChangeSuggesterProjectToProjects < EasyExtensions::EasyDataMigration
  def up
    setting = EasySetting.find_by(name: 'easy_search_suggester')
    if setting
      value = setting.value || {}
      if value['entity_types'] && (index = value['entity_types'].index('project'))
        value['entity_types'][index] = 'projects'
        setting.update(value: value)
      end
    end
  end

  def down
  end
end
