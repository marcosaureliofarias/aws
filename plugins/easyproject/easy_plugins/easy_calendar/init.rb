Redmine::Plugin.register :easy_calendar do
  name :easy_calendar_plugin_name
  author :easy_calendar_plugin_author
  author_url :easy_calendar_plugin_author_url
  description :easy_calendar_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/meeting-manager'
  version '2019'
  migration_order 300
  categories [:advanced]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end

# No more lines here!
