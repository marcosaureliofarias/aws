Redmine::Plugin.register :easy_to_do_list do
  name :easy_to_do_list_plugin_name
  author :easy_to_do_list_plugin_author
  author_url :easy_to_do_list_plugin_author_url
  description :easy_to_do_list_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/to-do-list'
  version '2019'
  migration_order 300
  categories [:basic]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')

  settings :partial => 'extensions/settings/easy_to_do_list', :default => {'enable_more_to_do_lists' => '0'}
end
