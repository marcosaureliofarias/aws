Redmine::Plugin.register :easy_money do
  name :easy_money_plugin_name
  author :easy_money_plugin_author
  author_url :easy_money_plugin_author_url
  description :easy_money_plugin_description
  store_url 'http://www.easyredmine.com/online-store/easy-redmine-plugins/money'
  version '2019'
  migration_order 300
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'
  depends_on [:easy_budgetsheet]
  categories [:finance]
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
