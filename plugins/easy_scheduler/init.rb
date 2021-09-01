Redmine::Plugin.register :easy_scheduler do
  name 'Easy Scheduler'
  description 'Cool personal scheduler for redmine'
  author 'Easy Software Ltd'
  author_url 'www.easysoftware.com'
  version '1.0'

  requires_redmine version_or_higher: '3.2'
  requires_redmine_plugin :easy_resource_base, version_or_higher: '0'
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

if Gem::Version.new(RedmineExtensions::VERSION) < Gem::Version.new('0.2.14')
  raise Gem::DependencyError, 'Redmine extensions version cannot be lower than 0.2.14'
end
