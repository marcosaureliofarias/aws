Redmine::Plugin.register :easy_gantt_resources do
  if Redmine::Plugin.installed?(:easy_extensions)
    name :easy_gantt_resources_plugin_name
    author :easy_gantt_resources_author
    description :easy_gantt_resources_description
    author_url :easy_gantt_resources_author_url
  else
    name 'Resource Management'
    author 'Easy Software Ltd'
    description 'new Resources management view for Easy gantt'
    author_url 'www.easysoftware.com'
  end
  version '1.6'

  requires_redmine_plugin :easy_gantt, version_or_higher: '1.9'

  if Redmine::Plugin.installed?(:easy_extensions)
    categories [:resource]
    depends_on [:easy_gantt]
  end

  settings partial: 'easy_gantt_resources_nil', only_easy: true, easy_settings: {
    hours_per_day: '8',
    advance_hours_per_days: ['8', '8', '8', '8', '8', '0', '0'],
    users_hours_limits: {},
    users_advance_hours_limits: {},
    users_estimated_ratios: {},
    default_zoom: 'week',
    default_allocator: 'from_end',
    change_allocator_enabled: false,
    hide_planned_tasks_enabled: false,
    show_task_soonest_start: false,
    show_task_latest_due: false,
    show_total_project_allocations: false,
    watchdog_enabled: false,
    show_free_capacities: false,
    show_groups: false,
    decimal_allocation: false,
    advance_hours_definition: false,
    with_projects: false,
    reservation_enabled: false
  }
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

unless Rails.root.join('plugins/easy_resource_base/init.rb').file?
  raise Redmine::PluginNotFound, 'Plugin easy_resource_base not found'
end
