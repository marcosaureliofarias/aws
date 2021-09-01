Redmine::Plugin.register :easy_resource_base do
  name 'Easy Resource Base'
  author 'Easy Software Ltd'
  author_url 'www.easysoftware.com'
  version '1.0'

  if Redmine::Plugin.installed?(:easy_extensions)
    visible false
    should_be_disabled false
  end

  # Into easy_settings goes available setting as a symbol key, default value as a value
  settings easy_settings: {}
end

unless Redmine::Plugin.registered_plugins[:easy_extensions]
  require_relative 'after_init'
end
