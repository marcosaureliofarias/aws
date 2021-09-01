class EpmIssuesAssignedToMe < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    settings['visible_issues'] ||= 'assigned'

    query = EasyIssueQuery.new(name: 'My', column_names: [:subject, :project, :done_ratio, :due_date])
    query.set_sort_params(settings)
    query.add_filter('status_id', 'o', nil)
    query.add_filter('is_planned', '=', ['0'])
    query.add_filter('project_is_closed', '=', ['0'])
    query.show_sum_row       = query.default_show_sum_row
    query.load_groups_opened = query.default_load_groups_opened
    query.show_avatars       = query.default_show_avatars
    if settings['visible_issues'] == 'assigned'
      query.add_filter('assigned_to_id', '=', [user.id.to_s])
    elsif settings['visible_issues'] == 'conserns'
      query.column_names += [:assigned_to, :author]
      query.add_filter('participant_id', '=', [user.id.to_s])
    end

    issues_count = query.entity_count

    assigned_issues = query.prepare_html_result(limit: get_row_limit(settings['row_limit']), preload: [:favorited_by])

    issues_count    ||= 0
    assigned_issues ||= {}

    { query: query, assigned_issues: assigned_issues, issues_count: issues_count, only_assigned: (settings['visible_issues'] == 'assigned') }
  end

  def deprecated?
    true
  end

end
