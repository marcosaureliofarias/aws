easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(File.dirname(__FILE__), 'app')

if easy_extensions
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_page_modules')

  EasyExtensions::PatchManager.register_easy_page_helper 'EasyGanttHelper'
  EpmEasyGlobalGantt.register_to_all(plugin: :easy_gantt_pro)
  EpmEasyProjectGantt.register_to_scope(:project, plugin: :easy_gantt_pro)

  Rails.application.configure do
    config.assets.precompile.concat([
      'easy_gantt_pro.js',
      'easy_gantt_pro_global',
      'easy_gantt_pro.css',
      'add_task',
      'sorting'
    ].map { |file| "easy_gantt_pro/#{file}" })
  end
end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_gantt_pro/proposer' if easy_extensions
end

RedmineExtensions::Reloader.to_prepare do
  require_dependency 'easy_gantt_pro/hooks'
end

Redmine::MenuManager.map :easy_gantt_tools do |menu|
  menu.delete(:add_task)
  menu.delete(:critical)
  menu.delete(:baseline)

  menu.push(:baseline, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt.button.create_baseline',
    html: { icon: 'menu__toggler' },
    if: proc { |project|
      project.present? &&
      Redmine::Plugin.installed?(:easy_baseline) &&
      project.module_enabled?('easy_baselines') &&
      User.current.allowed_to?(:view_baselines, project)
    },
    after: :tool_panel)

  menu.push(:cashflow, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt_pro.cashflow.label_cashflow',
    html: { icon: 'menu__toggler', style: 'display:none' },
    if: proc { |project| EasyGantt.easy_money? && User.current.allowed_to?(:view_easy_money, project, global: true) },
    after: :tool_panel)

  menu.push(:unfix_relations, 'javascript:void(0)',
    caption: :'easy_gantt_pro.unfix_relations.label_unfix_relations',
    html: { icon: 'menu__toggler', style: 'display:none' },
    after: :tool_panel)

  menu.push(:critical, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt.button.critical_path',
    html: { icon: 'menu__toggler' },
    if: proc { |p| p.present? && EasySetting.value(:easy_gantt_critical_path) != 'disabled' },
    after: :tool_panel)

  menu.push(:add_task, 'javascript:void(0)',
    param: :project_id,
    caption: :label_new,
    html: { icon: 'menu__toggler' },
    if: proc { |project|
      project.present? &&
      User.current.allowed_to?(:edit_easy_gantt, project) &&
      (User.current.allowed_to?(:add_issues, project) ||
       User.current.allowed_to?(:manage_versions, project))
    },
    after: :tool_panel)

  menu.push(:ggrm, 'javascript:void(0)',
    caption: :'easy_gantt_pro.resources.label_resources',
    html: { icon: 'menu__toggler' },
    if: proc { |project|
      project.nil? && User.current.allowed_to_globally?(:view_global_easy_gantt_resources)
    })

  menu.push(:bulk_edit,'javascript:void(0)',
    caption: :'easy_gantt.button.bulk_edit',
    html: { icon: 'menu__toggler' },
    if: proc { |project|
      !project.nil? && EasyGantt.easy_extensions?
    })

  menu.push(:delayed_project_filter, 'javascript:void(0)',
    caption: :'easy_gantt.button.delayed_project_filter',
    html: { icon: 'menu__toggler' },
    if: proc {
      EasySetting.value(:easy_gantt_show_project_progress)
    })

  # menu.push(:delayed_issue_filter, 'javascript:void(0)',
  #   caption: :'easy_gantt.button.delayed_issue_filter',
  #   html: { icon: 'menu__toggler' })

  menu.push(:show_lowest_progress_tasks, 'javascript:void(0)',
    caption: :'easy_gantt.button.show_lowest_progress_tasks',
    html: { icon: 'menu__toggler' },
    if: proc { |project|
      project.nil? && EasySetting.value(:easy_gantt_show_lowest_progress_tasks)
    })

end
