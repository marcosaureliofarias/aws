easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(File.dirname(__FILE__), 'app')

if easy_extensions
  RedmineExtensions::PatchManager.register_easy_page_controller 'EasyResourceDashboardController'
  RedmineExtensions::PatchManager.register_easy_page_helper 'EasyResourceDashboardHelper'

  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_page_modules')
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_queries')

  EpmUsersUtilization.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
  EpmGroupsUtilization.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
  EpmTrackersAllocations.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
  EpmTopUserUtilization.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
  EpmEasyGanttResources.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
  EpmAllocatedResources.register_to_page('easy-resource-dashboard', plugin: :easy_resource_dashboard)
end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do
  require 'easy_resource_dashboard/internals'
  require 'easy_resource_dashboard/hooks'
end

# this block is executed once just after Redmine is started
# means after all plugins are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in Redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_resource_dashboard/proposer' if easy_extensions
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:easy_resource_dashboard, :easy_resource_dashboard_path,
    html: { class: 'icon icon-resource-dashboard' },
    after: :easy_gantt_resources,
    caption: :button_top_menu_easy_resource_dashboard,
    if: proc { User.current.allowed_to_globally?(:view_easy_resource_dashboard) })
end

RedmineExtensions::Reloader.to_prepare do
  Redmine::AccessControl.map do |map|
    map.project_module :easy_gantt do |pmap|
      # View resource dashboard
      pmap.permission(:view_easy_resource_dashboard, {
        easy_resource_dashboard: [:index, :redmine]
      }, global: true, read: true)

      if easy_extensions
        # Edit resource dashboard
        pmap.permission(:edit_easy_resource_dashboard, {
          easy_resource_dashboard: [:layout]
        }, global: true, require: :loggedin)
      end

    end
  end
end
