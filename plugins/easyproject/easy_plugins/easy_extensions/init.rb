Redmine::Plugin.register :easy_extensions do
  name :easyproject_name
  author :easyproject_author
  author_url :easyproject_author_url
  description :easyproject_description
  version '2019'
  version_description :easyproject_version_description
  migration_order 200
  should_be_disabled false
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')

  requires_redmine version_or_higher: '4.1.0'

  settings easy_settings: {
      journal_history_limit: 10
  }
end
