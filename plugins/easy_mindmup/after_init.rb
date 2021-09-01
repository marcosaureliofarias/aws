RedmineExtensions::Reloader.to_prepare do
  require_relative './lib/easy_mindmup/easy_mindmup'
end

ActiveSupport.on_load(:easyproject, yield: true) do
  if Redmine::Plugin.installed?(:easy_theme_designer)
    EasyThemeDesign::TEMPLATES.concat(['mindmup', 'easy_mindmup_buffer', 'sass/_mindmup'])
  end
end
