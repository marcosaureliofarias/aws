easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(__dir__, 'app')

ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app', 'decorators')

if easy_extensions
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_queries')
  EasyQuery.register('EasySchedulerEasyQuery')
  EasyExtensions::PatchManager.register_easy_page_helper 'EpmEasySchedulerHelper'
end

# this block is executed once just after Redmine is started
# means after all plugins are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in Redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_scheduler/easy_scheduler'
  require 'easy_scheduler/hooks'
  require 'easy_scheduler/menus'
  EpmScheduler.register_to_all

  if EasyScheduler.easy_calendar?
    require 'easy_scheduler/easy_gantt_resource_calendar_event'
  end

  if EasyExtensions::EasyProjectSettings.respond_to?(:quick_calendar_url)
    EasyExtensions::EasyProjectSettings.quick_calendar_url = proc {
      Rails.application.routes.url_helpers.easy_scheduler_quick_show_path
    }
  end

  if Redmine::Plugin.installed?(:easy_theme_designer)
    EasyThemeDesign::TEMPLATES.concat(['dhtmlxscheduler_terrace', 'scheduler', 'sass/_scheduler'])
  end
end
