easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(File.dirname(__FILE__), 'app')

ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'queries')

if easy_extensions
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_queries')
  EasyQuery.register('EasyGanttEasyIssueQuery')
  EasyQuery.register('EasyGanttEasyProjectQuery')

  # RedmineExtensions::QueryOutput.whitelist_outputs_for_query 'EasyGanttEasyIssueQuery', 'list'
  # RedmineExtensions::QueryOutput.whitelist_outputs_for_query 'EasyGanttEasyProjectQuery', 'list'

  Rails.application.configure do
    config.assets.precompile.concat([
      'easy_gantt.js',
      'easy_gantt.css',
    ].map { |file| "easy_gantt/#{file}" })
  end
end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do
  require 'easy_gantt/easy_gantt'
  require 'easy_gantt/hooks'

  EasySetting.map.boolean_keys(
    :easy_gantt_show_holidays,
    :easy_gantt_show_project_progress,
    :easy_gantt_show_lowest_progress_tasks,
    :easy_gantt_spent_time_ratio_on_tasks,
    :easy_gantt_show_task_soonest_start,
    :easy_gantt_show_project_milestones
  )
end


Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:easy_gantt, { controller: 'easy_gantt', action: 'index', set_filter: 0 },
    caption: :label_easy_gantt,
    after: :documents,
    html: { class: 'icon icon-gantt' },
    if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt) })
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push(:easy_gantt, { controller: 'easy_gantt', action: 'index' },
    param: :project_id,
    caption: :button_project_menu_easy_gantt,
    if: proc { |p| User.current.allowed_to?(:view_easy_gantt, p) })
end

Redmine::MenuManager.map :easy_gantt_tools do |menu|
  menu.push(:back, 'javascript:void(0)',
            param: :project_id,
            caption: :button_back,
            html: { icon: 'icon-back' })

  menu.push(:task_control, 'javascript:void(0)',
            param: :project_id,
            caption: :button_edit,
            html: { icon: 'menu__toggler' })

  menu.push(:add_task, 'javascript:void(0)',
            param: :project_id,
            caption: :label_new,
            html: { trial: true, icon: 'menu__toggler' },
            if: proc { |p| p.present? })

  menu.push(:critical, 'javascript:void(0)',
            param: :project_id,
            caption: :'easy_gantt.button.critical_path',
            html: { trial: true, icon: 'menu__toggler' },
            if: proc { |p| p.present? })

  menu.push(:baseline, 'javascript:void(0)',
            param: :project_id,
            caption: :'easy_gantt.button.create_baseline',
            html: { trial: true, icon: 'menu__toggler' },
            if: proc { |p| p.present? })

  menu.push(:resource, proc { |project| defined?(EasyUserAllocations) ? { controller: 'user_allocation_gantt', project_id: project } : nil },
            param: :project_id,
            caption: :'easy_gantt.button.resource_management',
            html: { trial: true, icon: 'menu__toggler', easy_text: defined?(EasyExtensions) },
            if: proc { |p| p.present? })

end


# this block is executed once just after Redmine is started
# means after all plugins are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in Redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do

  if easy_extensions
    Redmine::MenuManager.map :projects_easy_page_layout_service_box do |menu|
      menu.push(:project_easy_gantt, :easy_gantt_path,
        caption: :label_easy_gantt,
        html: { class: 'icon icon-stats button button-2' },
        if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt) })
    end

    Redmine::MenuManager.map :easy_quick_top_menu do |menu|
      menu.push(:project_easy_gantt, { controller: 'easy_gantt', action: 'index', id: nil, set_filter: 0 },
        caption: :label_easy_gantt,
        parent: :projects,
        html: { class: 'icon icon-stats' },
        if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt) })

      menu.push(:issues_easy_gantt, { controller: 'easy_gantt', action: 'index', id: nil, set_filter: 0 },
        caption: :label_easy_gantt,
        parent: :issues,
        html: { class: 'icon icon-stats project-gantt' },
        if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt) })
    end
  end

  if Redmine::Plugin.installed?(:easy_theme_designer)
    plugin = Redmine::Plugin.find(:easy_gantt)
    %w[dhtmlxgantt sass/_gantt _easy_gantt].each do |file|
      EasyThemeDesign::TEMPLATES << File.join(plugin.id.to_s, file)
    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  # This access control is used by the plugins listed below
  # Logic is also copied on easy_resource_base
  #
  # easy_gantt
  # easy_gantt_pro
  # easy_resource_base
  # easy_scheduler
  #
  Redmine::AccessControl.map do |map|
    map.project_module :easy_gantt do |pmap|
      # View project level
      pmap.permission(:view_easy_gantt, {
        easy_gantt: [:index, :issues, :projects],
        easy_gantt_pro: [:lowest_progress_tasks, :cashflow_data],
        # easy_gantt_reservations: [:index]
      }, read: true)

      # Edit project level
      pmap.permission(:edit_easy_gantt, {
        easy_gantt: [:change_issue_relation_delay, :reschedule_project],
        easy_gantt_reservations: [:new, :bulk_update_or_create, :bulk_destroy]
      }, require: :member)

      # View global level
      pmap.permission(:view_global_easy_gantt, {
        easy_gantt: [:index, :issues, :projects, :project_issues],
        easy_gantt_pro: [:lowest_progress_tasks, :cashflow_data],
        # easy_gantt_reservations: [:index],
        easy_scheduler: [:index, :data],
      }, global: true, read: true)

      # Edit global level
      pmap.permission(:edit_global_easy_gantt, {
        easy_gantt_reservations: [:new, :bulk_update_or_create, :bulk_destroy],
        easy_scheduler: [:save],
      }, global: true, require: :loggedin)

      # View personal level
      pmap.permission(:view_personal_easy_gantt, {
        # easy_gantt_reservations: [:index],
        easy_scheduler: [:personal, :data],
      }, global: true, read: true)

      # Edit personal level
      pmap.permission(:edit_personal_easy_gantt, {
        easy_gantt_reservations: [:new, :bulk_update_or_create, :bulk_destroy],
        easy_scheduler: [:save],
      }, global: true, require: :loggedin)
    end
  end

end
