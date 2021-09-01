Redmine::Plugin.register :easy_calculation do
  name :easy_calculation_plugin_name
  author :easy_calculation_plugin_author
  author_url :easy_calculation_plugin_author_url
  description :easy_calculation_plugin_description
  version '2019'
  migration_order 300
  categories [:finance]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
