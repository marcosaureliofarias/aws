Redmine::Plugin.register :easy_crm do
  name :easy_crm_plugin_name
  author :easy_crm_plugin_author
  author_url :easy_crm_plugin_author_url
  description :easy_crm_plugin_description
  version '2019'
  migration_order 300
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  depends_on [:easy_contacts]
  categories [:customers]

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end

# No more lines here!
