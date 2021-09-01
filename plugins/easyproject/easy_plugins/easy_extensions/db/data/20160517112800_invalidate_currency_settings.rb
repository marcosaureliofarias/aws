class InvalidateCurrencySettings < EasyExtensions::EasyDataMigration
  def up
    setting       = EasySetting.find_or_initialize_by(name: 'easy_currencies_initialized', project_id: nil)
    setting.value = false
    setting.save
  end

  def down
    setting       = EasySetting.find_or_initialize_by(name: 'easy_currencies_initialized', project_id: nil)
    setting.value = true
    setting.save
  end
end
