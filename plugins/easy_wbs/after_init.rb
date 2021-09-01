app_dir = File.join(File.dirname(__FILE__), 'app')

if Redmine::Plugin.installed?(:easy_extensions)
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_queries')
  EasyQuery.register('EasyWbsEasyIssueQuery')
  Rails.application.configure do
    config.assets.precompile << 'easy_wbs.dart.js'
  end
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push(:easy_wbs, { controller: 'easy_wbs', action: 'index'},
    param: :project_id,
    caption: :'easy_wbs.button_project_menu')
end

Redmine::AccessControl.map do |map|
  map.project_module :easy_wbs do |pmap|
    pmap.permission :view_easy_wbs, { easy_wbs: [:index, :budget, :budget_overview, :budget_links] }, read: true
  end
end

RedmineExtensions::Reloader.to_prepare do
  require_relative './lib/easy_wbs/hooks'
  require_relative './lib/easy_wbs/easy_wbs'

  EasySetting.map.boolean_keys(:easy_wbs_no_sidebar)
end
