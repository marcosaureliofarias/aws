Redmine::Plugin.register :easy_knowledge do
  name :easy_knowledge_name
  author :easy_knowledge_author
  author_url :easy_knowledge_author_url
  description :easy_knowledge_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/knowledge-base-documentation-system'
  version '2019'
  migration_order 300
  categories [:advanced]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
