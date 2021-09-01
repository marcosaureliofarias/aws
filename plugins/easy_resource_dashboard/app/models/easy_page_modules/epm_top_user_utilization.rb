class EpmTopUserUtilization < EasyPageModule

  def category_name
    @category_name ||= 'easy_resource_dashboard'
  end

  def get_show_data(settings, user, page_context={})
    add_additional_filters_from_global_filters!(page_context, settings)

    count = settings['count'].to_i
    reverse = settings['reverse'].to_s.to_boolean
    r_table = EasyGanttResource.table_name
    u_table = User.table_name

    if (project_id = get_global_project_id(settings)).present?
      resource_ids = EasyGanttResource.joins(:issue).where(issues: { project_id: project_id }).pluck(:id).join(',')
      joins_statement = "INNER JOIN #{r_table} ON #{u_table}.id = #{r_table}.user_id AND #{r_table}.id IN (#{resource_ids.present? ? resource_ids : "''"})"
    else
      joins_statement = "LEFT OUTER JOIN #{r_table} ON #{u_table}.id = #{r_table}.user_id"
    end

    top_users_utilizations = User.active.
      select("#{u_table}.*, SUM(COALESCE(#{r_table}.hours, 0)) AS resources_hours").
      joins(joins_statement).
      group("#{u_table}.id").
      limit(count)

    if (group_id = get_global_group_id(settings)).present?
      top_users_utilizations = top_users_utilizations.joins(:groups).where(groups_users: {id: Array(group_id)})
    end

    if reverse
      top_users_utilizations = top_users_utilizations.order("resources_hours ASC, #{u_table}.id ASC")
    else
      top_users_utilizations = top_users_utilizations.order("resources_hours DESC, #{u_table}.id DESC")
    end

    { count: count, reverse: reverse, top_users_utilizations: top_users_utilizations }
  end

  def get_edit_data(settings, user, page_context={})
    { available_global_filters: available_global_filters }
  end

  def available_global_filters
    {
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
end
