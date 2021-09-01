Redmine::Plugin.register :easy_buttons do
  name :easy_buttons_plugin_name
  author :easy_buttons_plugin_author
  author_url :easy_buttons_plugin_author_url
  description :easy_buttons_plugin_description
  version '2019'
  migration_order 300
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end

# No more lines here!
