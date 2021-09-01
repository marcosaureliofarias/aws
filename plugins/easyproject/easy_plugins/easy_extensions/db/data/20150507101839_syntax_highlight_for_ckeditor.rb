class SyntaxHighlightForCkeditor < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'ckeditor_syntax_highlight_enabled', value: true)
    EasySetting.create!(name: 'ckeditor_syntax_highlight_theme', value: 'github')
  end

  def down
    EasySetting.where(name: ['ckeditor_syntax_highlight_enabled', 'ckeditor_syntax_highlight_theme']).destroy_all
  end
end
