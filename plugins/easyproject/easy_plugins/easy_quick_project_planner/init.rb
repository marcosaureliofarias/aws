Redmine::Plugin.register :easy_quick_project_planner do
  name :easy_quick_project_planner_plugin_name
  author :easy_quick_project_planner_plugin_author
  author_url :easy_quick_project_planner_plugin_author_url
  description :easy_quick_project_planner_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/quick-project-planner'
  version '2019'
  migration_order 300
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
  categories [:basic]

  settings :partial => 'extensions/settings/easy_quick_project_planner', :default => {}
end
