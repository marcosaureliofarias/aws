Redmine::Plugin.register :easy_alerts do
  name :alerts_plugin_name
  author :alerts_plugin_author
  author_url :alerts_plugin_author_url
  description :alerts_plugin_description
  store_url('http://www.easyredmine.com/online-store/easy-redmine-plugins/alerts-early-warning-system')
  version '2019'
  migration_order(300)
  categories [:advanced]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory(File.join('easyproject', 'easy_plugins'))
end
