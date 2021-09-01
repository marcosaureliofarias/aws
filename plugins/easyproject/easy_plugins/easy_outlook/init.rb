Redmine::Plugin.register :easy_outlook do
  name 'Easy Outlook'
  author 'Easy Software Ltd'
  description 'Extended CalDav'
  version '1.1'
  url 'www.easysoftware.com'

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
