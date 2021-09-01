class EpmPersonalEasyAgileBoard < EasyPageModule

  TRANSLATABLE_KEYS = [
    %w[heading]
  ]

  def category_name
    @category_name ||= 'easy_agile_board'
  end

  def permissions
    @permissions ||= [:view_easy_scrum_board]
  end

  def get_edit_data(settings, user, page_context = {})
    project = page_context[:project] || Project.find_by(id: settings['project_id'])
    swimlanes_for_autocomplete = EasyAgileBoardQuery.available_swimlanes
    swimlanes_for_autocomplete.delete_if{|swimlane| swimlane[:value] == 'project_id' }
    swimlanes_for_autocomplete = swimlanes_for_autocomplete.map{|swimlane| [swimlane[:name], swimlane[:value]] }

    { project: project, swimlanes_for_autocomplete: swimlanes_for_autocomplete, settings: settings }
  end

  def get_show_data(settings, user, page_context = {})
    if page_context[:project]
      project = page_context[:project]
    elsif settings['project_id'].present?
      project = Project.find_by(id: settings['project_id'])
    end

    if project
      easy_sprint = project.current_easy_sprint
      dont_use_project = easy_sprint.try(:cross_project?)
      query = EasyAgileBoardQuery.new(name: settings['heading'] || 'Scrum', dont_use_project: dont_use_project)
      query.project = project unless dont_use_project
      query.easy_sprint = easy_sprint

      if settings['only_me'] == '1'
        user_id = (user || User.current).id
        query.add_filter('assigned_to_id', '=', user_id)
        query.only_assigned = true
      end
    end

    settings['swimlane'] = EasySetting.value('scrum_output_setting')['default_swimlane'] if settings['swimlane'].blank?

    {query: query, project: project, easy_sprint: easy_sprint, settings: settings}
  end

end
