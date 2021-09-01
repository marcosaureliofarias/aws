Redmine::Plugin.register :easy_agile_board do
  name :easy_agile_board_plugin_name
  author :easy_agile_board_plugin_author
  author_url :easy_agile_board_plugin_author_url
  description :easy_agile_board_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/easy-agile-board'
  version '2019'
  migration_order 300
  categories [:advanced]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')

  settings default: {}
end

# No more lines here!
