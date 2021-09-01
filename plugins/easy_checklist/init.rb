Redmine::Plugin.register :easy_checklist do
  name 'Easy checklist'
  author 'Easy Software'
  description 'This is a plugin for creating checklists on issues etc.'
  version '2019'
  url 'http://www.easyproject.cz/en'
  author_url 'http://www.easyproject.cz/en'
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
