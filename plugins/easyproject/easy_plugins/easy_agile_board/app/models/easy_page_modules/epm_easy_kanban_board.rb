class EpmEasyKanbanBoard < EasyPageModule

  TRANSLATABLE_KEYS = [
    %w[heading]
  ]

  def category_name
    @category_name ||= 'easy_agile_board'
  end

  def permissions
    @permissions ||= [:view_easy_kanban_board]
  end

  def get_edit_data(settings, user, page_context = {})
    projects = page_context[:project] ? nil : Project.active_and_planned.where(Project.allowed_to_condition(User.current, :view_easy_kanban_board))
    swimlanes_for_autocomplete = EasyAgileBoardQuery.available_swimlanes
    swimlanes_for_autocomplete.delete_if{|swimlane| swimlane[:value] == 'project_id' }
    swimlanes_for_autocomplete = swimlanes_for_autocomplete.map{|swimlane| [swimlane[:name], swimlane[:value]] }

    { project: page_context[:project], projects: projects, swimlanes_for_autocomplete: swimlanes_for_autocomplete, settings: settings }
  end

  def get_show_data(settings, user, page_context = {})
    if page_context[:project]
      project = page_context[:project]
    elsif settings['project_id'].present?
      project = Project.find_by(id: settings['project_id'])
    end

    if project
      query = EasyAgileBoardQuery.new(name: settings['heading'] || 'Kanban')
      query.project = project

      if settings['only_me'] == '1'
        user_id = (user || User.current).id
        query.add_filter('assigned_to_id', '=', user_id)
        query.only_assigned = true
      end
    end

    settings['swimlane'] = EasySetting.value('kanban_output_setting')['default_swimlane'] if settings['swimlane'].blank?

    { query: query, project: project, settings: settings }
  end

end
