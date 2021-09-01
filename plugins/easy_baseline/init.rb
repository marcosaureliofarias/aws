Redmine::Plugin.register :easy_baseline do
  name 'Easy Baseline'
  author 'Easy Software'
  author_url 'http://www.easyproject.cz/en'
  description 'Allow to create a snapshot of a project in time.'
  version '1.3'

  # Into easy_settings goes available setting as a symbol key, default value as a value
  settings partial: false, easy_settings: {}
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
