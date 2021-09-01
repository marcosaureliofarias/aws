Redmine::Plugin.register :easy_vue do
  name 'Easy Vue'
  author 'Easy Software Ltd'
  author_url 'www.easysoftware.com'
  version '1.0'
  description ''

  #into easy_settings goes available setting as a symbol key, default value as a value
  settings easy_settings: {  }
  visible false
  should_be_disabled false
end

