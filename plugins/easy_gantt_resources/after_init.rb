easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(File.dirname(__FILE__), 'app')

ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'queries')

# Others
if easy_extensions
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_page_modules')
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_queries')

  EasyQuery.register('EasyResourceEasyQuery')
  EasyQuery.register('EasyLightResourceQuery')

  EasyExtensions::PatchManager.register_easy_page_helper 'EasyGanttHelper'
  EpmEasyGanttResources.register_to_all(plugin: :easy_gantt_resources)
  EpmPersonalEasyGanttResources.register_to_all(plugin: :easy_gantt_resources)

  Rails.application.configure do
    config.assets.precompile.concat([
      'easy_gantt_resources.js',
      'easy_gantt_resources.css',
      'easy_gantt_global_resources',
      'rm_renderer',
      'rm_planned',
      'rm_free_capacity'
    ].map { |file| "easy_gantt_resources/#{file}" })
  end

end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_gantt_resources/proposer' if easy_extensions

  Redmine::AccessControl.map do |map|
    map.permission :manage_user_easy_gantt_resources, {}, :global => true
  end
end

ActiveSupport.on_load(:after_initialize) do
  patched = 'EasySwagger::User'.safe_constantize
  patch   = 'EasyGanttResources::EasySwaggerUserPatch'.safe_constantize
  if patched && patch
    patched.include(patch) unless patched.include?(patch)
  end
end

RedmineExtensions::Reloader.to_prepare do
  require 'easy_gantt_resources/easy_gantt_resources'
  require 'easy_gantt_resources/resource_query_common'
  require 'easy_gantt_resources/hooks'

  EasySetting.map.boolean_keys(:easy_gantt_resources_hide_planned_tasks_enabled, :easy_gantt_resources_change_issue_allocator, :easy_gantt_resources_show_task_soonest_start, :easy_gantt_resources_show_total_project_allocations, :easy_gantt_resources_change_allocator_enabled, :easy_gantt_resources_watchdog_enabled, :easy_gantt_resources_show_free_capacities, :easy_gantt_resources_show_groups, :easy_gantt_resources_decimal_allocation, :easy_gantt_resources_advance_hours_definition, :easy_gantt_resources_with_projects, :easy_gantt_resources_show_task_latest_due, :easy_gantt_resources_groups_holidays_enabled, :easy_gantt_resources_reservation_enabled)

  EasySetting.map.key(:easy_gantt_resources_hours_per_day) do
    from_params do |raw_value|
      raw_value.to_f.to_s
    end
  end

  EasySetting.map.keys(:easy_gantt_resources_users_hours_limits, :easy_gantt_resources_users_estimated_ratios) do
    from_params do |raw_value|
      if raw_value.is_a?(Hash) || raw_value.is_a?(ActionController::Parameters)
        result = {}

        raw_value.each do |user, val|
          next if val.blank?
          val = val.to_s.tr(',', '.')
          result[user] = val.to_f.to_s
        end

        result
      else
        {}
      end
    end
  end

  EasySetting.map.key(:easy_gantt_resources_users_advance_hours_limits) do
    from_params do |raw_value|
      if raw_value.is_a?(Hash) || raw_value.is_a?(ActionController::Parameters)
        result = {}

        raw_value.each do |user, vals|
          vals.map! do |val|
            if val.present?
              val.tr(',', '.').to_f.to_s
            else
              ''
            end
          end

          if vals.any?(&:present?)
            result[user] = vals
          end
        end

        result
      else
        {}
      end
    end
  end
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:easy_gantt_resources, { controller: 'easy_gantt_resources', action: 'index', set_filter: 0 },
    html: { class: 'icon icon-resource-management' },
    after: :easy_gantt,
    caption: :button_top_menu_easy_gantt_resources,
    if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt_resources) })
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push(:resource, { controller: 'easy_gantt', action: 'index', gantt_type: 'rm' },
    param: :project_id,
    caption: :'easy_gantt_resources.buttons.button_project_menu',
    if: proc { |p| User.current.allowed_to?(:view_easy_gantt_resources, p) })
end

Redmine::MenuManager.map :easy_gantt_tools do |menu|
  menu.delete(:resource)
  menu.delete(:delayed_project_filter)
  menu.push(:resource, 'javascript:void(0)',
    html: {
      icon: 'menu__toggler',
      caption: proc { |type|
        if type == 'rm'
          I18n.t('button_project_menu_easy_gantt')
        else
          I18n.t('easy_gantt.button.resource_management')
        end
      }
    },
    param: :project_id,
    before: :problem_finder,
    caption: ':resource_or_gantt',
    if: proc { |p| User.current.allowed_to?(:view_easy_gantt, p) || User.current.allowed_to?(:view_easy_gantt_resources, p) })

  menu.push(:rm_reallocate, 'javascript:void(0)',
    caption: :'easy_gantt.button.rm_reallocate',
    html: { icon: 'icon-reload' })

  menu.push(:rm_balance, 'javascript:void(0)',
    caption: :label_easy_gantt_resources_balance,
    html: { icon: 'icon-controls' })

  menu.push(:hide_planned_tasks, 'javascript:void(0)',
    caption: :button_hide_planned_tasks,
    html: { icon: 'menu__toggler' },
    if: proc {
      EasySetting.value(:easy_gantt_resources_hide_planned_tasks_enabled)
    })

  menu.push(:delayed_project_filter, 'javascript:void(0)',
    caption: :'easy_gantt.button.delayed_project_filter',
    html: { icon: 'menu__toggler' },
    if: proc {
      EasySetting.value(:easy_gantt_show_project_progress)
    })

  menu.push(:rm_free_capacity, 'javascript:void(0)',
    caption: :label_easy_gantt_resources_show_free_capacities,
    html: { icon: 'menu__toggler' })

  menu.push(:resource_reservations, 'javascript:void(0)',
    caption: :'easy_gantt_resources.buttons.rm_reservations',
    html: { icon: 'menu__toggler' },
    if: proc {
      EasySetting.value(:easy_gantt_resources_reservation_enabled)
    })

  menu.push(:resource_with_projects, 'javascript:void(0)',
    caption: :'easy_gantt_resources.buttons.rm_with_projects',
    html: { icon: 'menu__toggler' })

  menu.push(:resource_with_milestones, 'javascript:void(0)',
    caption: :'easy_gantt_resources.buttons.rm_with_milestones',
    html: { icon: 'menu__toggler' })

  menu.push(:hide_tasks, 'javascript:void(0)',
            caption: :'easy_gantt_resources.buttons.rm_hide_tasks',
            html: { icon: 'menu__toggler' })

  menu.push(:hide_reservations, 'javascript:void(0)',
            caption: :'easy_gantt_resources.buttons.rm_hide_reservations',
            html: { icon: 'menu__toggler' })

end

if easy_extensions
  Redmine::MenuManager.map :projects_easy_page_layout_service_box do |menu|
    menu.push(:easy_gantt_resources, :easy_gantt_resources_path,
      html: { trial: true, class: 'button icon icon-stats' },
      caption: :'easy_gantt.button.resource_management',
      if: proc { User.current.allowed_to_globally?(:view_global_easy_gantt_resources) })
  end
end

RedmineExtensions::Reloader.to_prepare do

  Redmine::AccessControl.map do |map|
    map.project_module :easy_gantt_resources do |pmap|
      # View project level
      pmap.permission(:view_easy_gantt_resources, {
        easy_gantt_resources: [:index, :project_data, :users_sums, :projects_sums, :allocated_issues],
        easy_gantt: [:index, :issues]
      }, read: true)

      # Edit project level
      pmap.permission(:edit_easy_gantt_resources, {
        easy_gantt_resources: [:bulk_update_or_create]
      }, require: :member)

      # View global level
      pmap.permission(:view_global_easy_gantt_resources, {
        easy_gantt_resources: [:index, :project_data, :global_data, :projects_sums, :allocated_issues],
        easy_gantt: [:index, :issues]
      }, global: true, read: true)

      # Edit global level
      pmap.permission(:edit_global_easy_gantt_resources, {
        easy_gantt_resources: [:bulk_update_or_create]
      }, global: true, require: :loggedin)

      # View personal level
      pmap.permission(:view_personal_easy_gantt_resources, {
        easy_gantt_resources: [:global_data]
      }, global: true, read: true)

      # Edit personal level
      pmap.permission(:edit_personal_easy_gantt_resources, {
        easy_gantt_resources: [:bulk_update_or_create]
      }, global: true, require: :loggedin)
    end
  end

end
