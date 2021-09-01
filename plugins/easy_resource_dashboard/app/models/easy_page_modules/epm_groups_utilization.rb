class EpmGroupsUtilization < EasyPageModule

  def category_name
    @category_name ||= 'easy_resource_dashboard'
  end

  def get_show_data(settings, user, page_context={})
    add_additional_filters_from_global_filters!(page_context, settings)
    groups = Group.visible.preload(:users).where(id: get_global_group_id(settings))
    days = settings['days'].to_i
    if ![7, 30, 90].include?(days)
      days = 7
    end

    { groups: groups, days: days, additional_filters: settings['additional_filters'] }
  end

  def get_edit_data(settings, user, page_context={})
    { available_global_filters: available_global_filters }
  end

  def available_global_filters
    {
      project: [{ name: l(:field_project), filter: 'project_id' }],
      user_group: [{ name: l(:field_group), filter: 'group_id' }]
    }
  end

  def get_global_group_id(settings)
    global_filter_group_id = settings.dig('additional_filters', 'group_id')
    return Array(global_filter_group_id) if global_filter_group_id.present?
    Array(settings['groups_id'])
  end

end
