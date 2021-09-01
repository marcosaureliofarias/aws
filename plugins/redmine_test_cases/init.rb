Redmine::Plugin.register :redmine_test_cases do
  name 'Test Cases'
  author ''
  author_url ''
  description ''
  version '2019-03-18'

  #into easy_settings goes available setting as a symbol key, default value as a value
  settings easy_settings: {  }
end

unless Redmine::Plugin.registered_plugins[:easy_extensions]
  require_relative 'after_init'
end
