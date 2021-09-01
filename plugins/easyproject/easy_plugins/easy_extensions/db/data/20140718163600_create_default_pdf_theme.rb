class CreateDefaultPdfTheme < EasyExtensions::EasyDataMigration

  def self.up
    EasyPdfTheme.create!(name: 'default', is_default: EasyPdfTheme.default ? false : true, easy_system_flag: true)
  end

  def self.down
    EasyPdfTheme.where(name: 'default').where(easy_system_flag: true).destroy_all
  end

end
