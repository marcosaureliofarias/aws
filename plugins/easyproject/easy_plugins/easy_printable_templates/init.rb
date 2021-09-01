Redmine::Plugin.register :easy_printable_templates do
  name :easy_printable_templates_plugin_name
  author :easy_printable_templates_plugin_author
  author_url :easy_printable_templates_plugin_author_url
  description :easy_printable_templates_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/customizable-printing-templates'
  version '2019'
  migration_order 300
  depends_on [:easy_data_templates]
  categories [:basic]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
