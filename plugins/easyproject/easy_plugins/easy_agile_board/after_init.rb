EasyExtensions::PatchManager.register_easy_page_helper 'EasyAgileBoardHelper', 'EasySprintsHelper'
EasyExtensions::PatchManager.register_easy_page_controller 'EasySprintsController'

EpmPersonalEasyAgileBoard.register_to_all(plugin: :easy_agile_board)
EpmEasyKanbanBoard.register_to_all(plugin: :easy_agile_board)
EpmEasySprintQuery.register_to_all(plugin: :easy_agile_board)

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_agile_board/hooks'
  require 'easy_agile_board/permissions'

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_scrum_board, { controller: 'easy_agile_board', action: 'show' }, caption: :label_scrum_board
    menu.push :easy_kanban_board, { controller: 'easy_kanban', action: 'show' }, caption: :label_kanban
  end

  Redmine::AccessControl.map do |map|
    map.easy_category :'easy_agile_board' do |cmap|
      cmap.permission :view_global_easy_sprints, { easy_sprints: [:global_index] }, read: true, global: true
      cmap.permission :view_easy_scrum_overview, { easy_sprints: [:overview] }, read: true, global: true
      cmap.permission :manage_easy_scrum_overview, { easy_sprints: [:layout] }, global: true
    end

    map.project_module(:easy_scrum_board) do |pmap|
      pmap.permission :view_easy_scrum_board, {
          easy_agile_board: [:show, :backlog, :burndown_chart],
          easy_sprints: [:show, :index, :autocomplete, :overview]
        }, read: true
      pmap.permission :manage_sprint_backlog, {
        easy_agile_board: [:recalculate, :reorder_project_backlog, :reorder_sprint_backlog],
        easy_sprints: [:assign_issue, :unassign_issue, :reorder]
      }
      pmap.permission :edit_easy_scrum_board, {
          easy_agile_board: [:settings, :recalculate, :reorder_project_backlog, :reorder_sprint_backlog],
          easy_sprints: [:new, :create, :edit, :update, :destroy, :assign_issue, :unassign_issue, :open, :close, :close_dialog, :reorder, :layout]
        }
    end

    map.project_module(:easy_kanban_board) do |pmap|
      pmap.permission :view_easy_kanban_board, {
          easy_kanban: [:show, :backlog]
        }, read: true
      pmap.permission :edit_easy_kanban_board, {
          easy_kanban: [:edit, :update, :settings, :recalculate],
          easy_kanban_issues: [:update, :reorder]
        }
    end

    Redmine::MenuManager.map :admin_menu do |menu|
      menu.push :easy_agile_default_settings,
                { controller: 'easy_agile_settings', action: 'index', tab: 'scrum' },
                html: { class: 'icon icon-bullet-list' },
                caption: :easy_agile_default_settings,
                if: proc { User.current.admin? },
                before: :settings
    end

    Redmine::MenuManager.map :top_menu do |menu|
      menu_options = {
        caption: :easy_agile_board_overview,
        after: :easy_resource_dashboard,
        if: proc { User.current.allowed_to_globally?(:view_easy_scrum_overview, {}) },
        html: { class: 'icon icon-agile'}
      }
      menu.push(:easy_agile_board, :overview_easy_sprints_path, menu_options)
      menu.push(:global_easy_sprint_query, :easy_sprints_path, {
        parent: :easy_agile_board,
        caption: :button_global_easy_sprint_query,
        if: proc { User.current.allowed_to_globally?(:view_global_easy_sprints, {}) }
      })
    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  require 'easy_agile_board/easy_agile_board'
  require_dependency 'easy_agile_board/easy_settings'
  require 'easy_agile_board/global_filters'

  EasySetting.map.boolean_keys(:easy_agile_use_workflow_on_sprint, :easy_agile_use_workflow_on_kanban, :add_new_issues_to_project_kanban)

  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyAgileBoard::EasyQueryOutputs::KanbanOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output_for_query EasyAgileBoard::EasyQueryOutputs::AgileScrumOutput, 'EasyAgileBoardQuery'
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output_for_query EasyAgileBoard::EasyQueryOutputs::AgileScrumBacklogOutput, 'EasyAgileBoardQuery'
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output_for_query EasyAgileBoard::EasyQueryOutputs::AgileKanbanOutput, 'EasyAgileBoardQuery'
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output_for_query EasyAgileBoard::EasyQueryOutputs::AgileKanbanBacklogOutput, 'EasyAgileBoardQuery'

  EasyQuery.map do |query|
    query.register 'EasyAgileBoardQuery'
    query.register 'EasySprintQuery'
  end

end

EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(page_name: 'easy-sprint-overview').first
  page_template = page.default_template

  unless page_template
    template_file = File.join EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_agile_board', 'assets', 'xml_data_store', 'dashboard_template.xml'
    EasyAgileBoard::Utils.import_default_template(template_file)
    EasyPageZoneModule.create_from_page_template(page.default_template) unless page.all_modules.exists?
  end
end
