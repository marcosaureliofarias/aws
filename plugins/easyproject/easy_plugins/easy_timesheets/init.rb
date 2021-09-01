Redmine::Plugin.register :easy_timesheets do
  name :easy_timesheets_plugin_name
  author :easy_timesheets_plugin_author
  author_url :easy_timesheets_plugin_author_url
  description :easy_timesheets_plugin_description
  version '2019'
  migration_order 300
  categories [:advanced]
  requires_redmine_plugin :easy_extensions, version_or_higher: '2019'

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')

  settings partial: 'easy_timesheets', easy_settings: { enabled_timesheet_period: [] }
end

# No more lines here!
