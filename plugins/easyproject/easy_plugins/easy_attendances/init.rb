Redmine::Plugin.register :easy_attendances do
  name :easy_attendances_plugin_name
  author :easy_attendances_plugin_author
  author_url :easy_attendances_plugin_author_url
  description :easy_attendances_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/attendance'
  version '2019'
  migration_order 300
  categories [:resource]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')

  settings :partial => false, :default => {}
end
