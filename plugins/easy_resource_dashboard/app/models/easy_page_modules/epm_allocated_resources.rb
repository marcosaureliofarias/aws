class EpmAllocatedResources < EasyPageModule

  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'easy_resource_dashboard'
  end

  def get_show_data(settings, user, page_context={})
    add_additional_filters_from_global_filters!(page_context, settings)
    range = chart_range(settings)
    from = range[:from] || Date.today - 3.months
    to = range[:to] || from + 180.days

    allocations_per_week = EasyGanttResource.where(date: from..to).reorder('year_weak').group('year_weak')
    timeentries_per_week = TimeEntry.where(spent_on: from..to).where.not(issue_id: nil).reorder('year_weak').group('year_weak')

    if (user_id = get_global_user_id(settings)).present?
      allocations_per_week = allocations_per_week.where(user_id: user_id)
      timeentries_per_week = timeentries_per_week.where(user_id: user_id)
    end

    if (project_id = get_global_project_id(settings)).present?
      allocations_per_week = allocations_per_week.joins(issue: :project).where(issues: { project_id: project_id })
      timeentries_per_week = timeentries_per_week.where(project_id: project_id)
    end

    if (group_id = get_global_group_id(settings)).present?
      allocations_per_week = allocations_per_week.joins(user: :groups).where(groups_users: {id: Array(group_id)})
      timeentries_per_week = timeentries_per_week.joins(user: :groups).where(groups_users: {id: Array(group_id)})
    end

    allocations_per_week = allocations_per_week.pluck(Arel.sql("#{year_weak_format('date')} AS year_weak, SUM(hours) AS sum")).to_h
    timeentries_per_week = timeentries_per_week.pluck(Arel.sql("#{year_weak_format('spent_on')} AS year_weak, SUM(hours) AS sum")).to_h

    values = []
    from.step(to, 7).each do |date|
      date = date.strftime('%Y-%W')

      values << {
        x: date,
        resource: allocations_per_week[date].to_f,
        time_entry: timeentries_per_week[date].to_f
      }
    end

    { range: range, values: values }
  end

  def get_edit_data(settings, user, page_context = {})
    {
      period_date_period_type: settings['period_date_period_type'].presence || '1',
      period_date_period: settings['period_date_period'].presence || 'all',
      period_start_date: (settings['period_start_date'].to_date rescue Date.today),
      period_end_date: (settings['period_end_date'].to_date rescue Date.today),
      available_global_filters: available_global_filters
    }
  end

  def available_global_filters
    {
      user: [{ name: l(:field_assigned_to), filter: 'user_id' }],
      project: [{ name: l(:field_project), filter: 'project_id' }],
      user_group: [{ name: l(:field_member_of_group), filter: 'group_id' }]
      # date_period: [{ name: l(:label_time), filter: 'period' }],
    }
  end

  def chart_range(settings)
    get_date_range(
      settings['period_date_period_type'],
      settings['period_date_period'],
      settings['period_start_date'],
      settings['period_end_date'],
    )
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

  def year_weak_format(field)
    case ActiveRecord::Base.connection.adapter_name.downcase
    when /(mysql|mariadb)/
      "DATE_FORMAT(#{field}, '%Y-%v')"
    when /postgresql/
      "to_char(#{field}, 'YYYY-IW')"
    end
  end

end
