class ChangeDefaultTheme < EasyExtensions::EasyDataMigration

  def up
    setting = EasySetting.find_or_initialize_by(name: "ui_theme")
    setting.update value: "themes/er18/er18.css"
  end

  def down
    EasySetting.where(name: "ui_theme").destroy_all
  end

end
