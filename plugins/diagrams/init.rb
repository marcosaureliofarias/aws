Redmine::Plugin.register :diagrams do
  name 'Diagrams'
  author 'CompanySolution'
  author_url 'https://companysolution.eu'
  description 'diagrams plugin'
  version '2016'

  settings :default => {}
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end