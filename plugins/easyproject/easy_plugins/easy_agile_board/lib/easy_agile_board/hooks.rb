module EasyAgileBoard
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_projects_show_bottom, partial: 'easy_agile_board/project_button'
    render_on :view_quick_project_planner_new_issue_form, partial: 'easy_agile_board/quick_project_planner_form'

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_scrum_board' if enabled_modules && enabled_modules.include?('easy_scrum_board')
      default_pages << 'easy_kanban_board' if enabled_modules && enabled_modules.include?('easy_kanban_board')
    end

    def helper_project_settings_tabs(context={})
      if User.current.allowed_to?(:edit_easy_scrum_board, context[:project])
        context[:tabs] << { name: 'scrum_board', action: :scrum_board, url: context[:controller].easy_agile_board_settings_path(context[:project]), label: :label_scrum_board, redirect_link: true }
      end
      if User.current.allowed_to?(:edit_easy_kanban_board, context[:project])
        context[:tabs] << { name: 'kanban_board', action: :kanban_board, url: context[:controller].project_easy_kanban_settings_path(context[:project]), label: :label_kanban, redirect_link: true }
      end
    end

    def helper_issues_render_hidden_issue_attribute_for_edit_bottom_left(context={})
      issue = context[:issue]
      return unless easy_agile_editable?(issue.project)
      issue_sprint = issue.easy_sprint_id ? issue.easy_sprint : nil
      sprints = EasyAgileBoard.easy_sprints_for_select(issue.project, append_sprint: issue_sprint)

      context[:controller].send(:render_to_string, partial: 'issues/easy_agile_board_form', locals: context.merge(sprints: sprints))
    end

    def view_issues_show_api_bottom(context={})
      issue = context[:issue]
      return unless easy_agile_readable?(issue.project)
      sprint = issue.easy_sprint
      unless sprint.nil?
        context[:api].easy_sprint(id: sprint.id, name: sprint.name, due_date: sprint.due_date)
        context[:api].easy_story_points issue.easy_story_points
      end
    end

    def view_issues_show_details_bottom(context={})
      issue = context[:issue]
      easy_agile_editable = easy_agile_editable?(issue.project)
      return unless easy_agile_editable || easy_agile_readable?(issue.project)

      context[:controller].send(:render_to_string,
                                partial: 'issues/easy_agile_board_view_issues_show_details_bottom',
                                locals: context.merge(easy_agile_editable: easy_agile_editable))
    end

    def view_mailer_issue_show_html_bottom(context={})
      issue = context[:issue]
      return unless easy_agile_readable?(issue.project)
      return if issue.easy_sprint.nil?
      context[:controller].send(:render_to_string, partial: 'issues/easy_agile_board_view_mailer_issue_show_html_bottom', locals: context)
    end

    def view_mailer_issue_show_text_bottom(context={})
      issue = context[:issue]
      return unless easy_agile_readable?(issue.project)
      return if issue.easy_sprint.nil?
      "#{l(:label_agile_sprint)}: #{issue.easy_sprint.name}".html_safe
    end

    def view_issues_context_menu_end(context = {})
      return if context[:project].nil? || context[:issues].blank?
      return unless easy_agile_editable?(context[:project])
      sprints = EasyAgileBoard.easy_sprints_for_autocomplete(context[:project])
      if sprints.present?
        context[:controller].send(:render_to_string, partial: 'context_menus/agile_board_view_context_menu_end', locals: { sprints: sprints })
      end

      if context[:options] && context[:options][:show_story_points]
        content_tag(:li, context[:hook_caller].context_menu_link(l(:label_add_estimate), 'javascript:void(0)', class: 'icon icon-add agile__context__edit__atribute', title: l(:label_add_estimate)))
      end
    end

    def view_issues_bulk_edit_details_bottom(context = {})
      return if context[:project].nil? || context[:issues].blank?
      return unless easy_agile_editable?(context[:project])
      sprints = EasyAgileBoard.easy_sprints_for_select(context[:project])
      context[:controller].send(:render_to_string, partial: 'issues/bulk_update_easy_agile_board', locals: { sprints: sprints, issue_params: context[:issue_params] })
    end

    def view_issues_form_details_bottom(context={})
      issue = context[:issue]
      helper_issues_render_hidden_issue_attribute_for_edit_bottom_left(context) if issue.new_record?
    end

    def easy_agile_editable?(project)
      return false if project.nil? || project.new_record?

      closest_agile_project = project.self_and_ancestors.has_module(:easy_scrum_board).reorder(lft: :desc).limit(1).first
      closest_agile_project && User.current.allowed_to?(:view_easy_scrum_board, closest_agile_project) && User.current.allowed_to?(:edit_easy_scrum_board, closest_agile_project)
    end

    def easy_agile_readable?(project)
      return false if project.nil? || project.new_record?

      closest_agile_project = closest_agile_project(project)
      closest_agile_project && User.current.allowed_to?(:view_easy_scrum_board, closest_agile_project)
    end

    def closest_agile_project(project)
      project.self_and_ancestors.has_module(:easy_scrum_board).reorder(lft: :desc).limit(1).first
    end

    def easy_agile_accessible?(project)
      return false if project.nil? || project.new_record?

      closest_agile_project = project.self_and_ancestors.has_module(:easy_scrum_board).reorder(lft: :desc).limit(1).first
      closest_agile_project && User.current.allowed_to?(:view_easy_scrum_board, closest_agile_project) &&
        (User.current.allowed_to?(:edit_easy_scrum_board, closest_agile_project) || User.current.allowed_to?(:manage_sprint_backlog, closest_agile_project))
    end

  end
end
