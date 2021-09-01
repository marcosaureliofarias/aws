Redmine::Plugin.register :easy_job do
  name 'Easy Job'
  author 'Easy Software Ltd'
  description 'Async job for Redmine, EasyRedmine and EasyProject'
  version '1.1'

  if Redmine::Plugin.installed?(:easy_extensions)
    should_be_disabled false
  end

  # Into easy_settings goes available setting as a symbol key, default value as a value
  settings easy_settings: { }
end

RedmineExtensions::Reloader.to_prepare do
  require 'easy_job'
end
