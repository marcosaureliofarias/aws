Redmine::Plugin.register :redmine_re do
  name :redmine_re_plugin_name
  description :redmine_re_plugin_description
  author :redmine_re_plugin_author
  author_url :redmine_re_plugin_author_url
  version '1.6.0'

  requires_redmine :version_or_higher => '3.4.6'
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end