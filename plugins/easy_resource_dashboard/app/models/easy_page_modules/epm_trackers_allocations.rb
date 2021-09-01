class EpmTrackersAllocations < EasyPageModule

  def category_name
    @category_name ||= 'easy_resource_dashboard'
  end

  def get_show_data(settings, user, page_context={})
    add_additional_filters_from_global_filters!(page_context, settings)

    t_table = Tracker.table_name
    r_table = EasyGanttResource.table_name

    tracker_ids = settings['tracker_ids']

    allocations_by_trackers = Tracker.select("#{t_table}.*, SUM(#{r_table}.hours) AS resources_hours").joins(issues: :easy_gantt_resources).where(trackers: { id: tracker_ids }).group("#{t_table}.id")

    if (user_id = get_global_user_id(settings)).present?
      allocations_by_trackers = allocations_by_trackers.where(easy_gantt_resources: { user_id: user_id })
    end

    if (project_id = get_global_project_id(settings)).present?
      allocations_by_trackers = allocations_by_trackers.joins(issues: :project).where(issues: { project_id: project_id })
    end

    if (group_id = get_global_group_id(settings)).present?
      allocations_by_trackers = allocations_by_trackers.joins(issues: {easy_gantt_resources: {user: :groups}}).where(groups_users: {id: Array(group_id)})
    end

    allocations_by_trackers = allocations_by_trackers.map { |t| [t.name, t.resources_hours.to_f] }

    {
      allocations_by_trackers: allocations_by_trackers
    }
  end

  def get_edit_data(settings, user, page_context={})
    {
      available_global_filters: available_global_filters
    }
  end

  def available_global_filters
    {
      user: [{ name: l(:field_assigned_to), filter: 'user_id' }],
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
