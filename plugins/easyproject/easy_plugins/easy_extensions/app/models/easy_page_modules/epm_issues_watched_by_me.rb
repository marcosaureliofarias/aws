class EpmIssuesWatchedByMe < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    query = EasyIssueQuery.new(name: 'Watched', column_names: [:subject, :project, :done_ratio, :due_date])
    query.set_sort_params(settings)
    query.add_filter('status_id', 'o', nil)
    query.add_filter('is_planned', '=', ['0'])
    query.add_filter('watcher_id', '=', [user.id.to_s])
    query.show_sum_row       = query.default_show_sum_row
    query.load_groups_opened = query.default_load_groups_opened
    query.show_avatars       = query.default_show_avatars
    issues_count             = query.entity_count

    watched_issues = query.prepare_html_result(limit: get_row_limit(settings['row_limit']), preload: [:favorited_by])

    issues_count   ||= 0
    watched_issues ||= {}

    { query: query, watched_issues: watched_issues, issues_count: issues_count }
  end

end
