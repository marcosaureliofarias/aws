Redmine::Plugin.register :easy_project_attachments do
  name :easy_project_attachments_plugin_name
  author :easy_project_attachments_plugin_author
  author_url :easy_project_attachments_plugin_author_url
  description :easy_project_attachments_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/project-attachments'
  version '2019'
  migration_order 300
  categories [:basic]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
