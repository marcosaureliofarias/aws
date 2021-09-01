Redmine::Plugin.register :easy_budgetsheet do
  name :budgetsheet_name
  author :budgetsheet_author
  author_url :budgetsheet_author_url
  description :budgetsheet_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/budgetsheet'
  version '2019'
  migration_order 300
  categories [:finance]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
