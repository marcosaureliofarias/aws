Redmine::Plugin.register :easy_helpdesk do
  name :easy_helpdesk_name
  author :easy_helpdesk_author
  author_url :easy_helpdesk_author_url
  description :easy_helpdesk_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/help-desk'
  version '2019'
  migration_order 300
  depends_on [:easy_alerts]
  categories [:customers]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
