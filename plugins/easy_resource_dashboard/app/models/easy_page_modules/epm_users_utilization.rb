class EpmUsersUtilization < EasyPageModule

  def category_name
    @category_name ||= 'easy_resource_dashboard'
  end

  def get_show_data(settings, user, page_context={})
    add_additional_filters_from_global_filters!(page_context, settings)

    user_ids = get_global_user_id(settings)
    user_ids = user_ids.present? ? Array(user_ids) : Array(settings['user_ids'])

    users = User.where(id: user_ids)
    days = settings['days'].to_i
    if ![7, 30, 90].include?(days)
      days = 7
    end

    from = Date.today
    to = from + days.days

    if (group_id = get_global_group_id(settings)).present?
      users = users.joins(:groups).where(groups_users: {id: Array(group_id)})
    end

    resources = EasyGanttResource.where(user_id: users).between_dates(from, to)

    if (project_id = get_global_project_id(settings)).present?
      resources = resources.joins(issue: :project).where(issues: { project_id: project_id } )
    end

    hours = resources.sum(:hours)

    { hours: hours, from: from, to: to, users: users }
  end

  def get_edit_data(settings, user, page_context={})
    selected_user = User.find_by(id: settings['user_ids']) if settings['user_ids'].present?
    {
      available_global_filters: available_global_filters,
      selected_user: selected_user
    }
  end

  def available_global_filters
    {
      user: [{ name: l(:field_user), filter: 'user_id' }],
      project: [{ name: l(:field_project), filter: 'project_id' }],
      user_group: [{ name: l(:field_member_of_group), filter: 'group_id' }]
    }
  end

  # assignee's group
  def get_global_group_id(settings)
    settings.dig('additional_filters', 'group_id')
  end

  def get_global_project_id(settings)
    settings.dig('additional_filters', 'project_id')
  end

  def get_global_user_id(settings)
    settings.dig('additional_filters', 'user_id')
  end
end
