class EpmPersonalEasyGanttResources < EasyPageModule

  def category_name
    @category_name ||= 'users'
  end

  def show_path
    if RequestStore.store[:epm_easy_gantt_active]
      'easy_gantt/already_active_error'
    else
      RequestStore.store[:epm_easy_gantt_active] = true
      super
    end
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_personal_easy_gantt_resources) &&
    user.allowed_to_globally?(:view_personal_easy_gantt)
  end

  def get_show_data(settings, user, page_context={})
    query = EasyResourceEasyQuery.new(name: l(:title_easy_gantt_personal_resources))
    query.filters = query.default_filter
    query.column_names = [:subject, :priority]

    query.ensure_period_filter
    default_period = query.filters['period']

    query.filters = {}
    query.add_filter('period', default_period[:operator], default_period[:values])
    query.add_filter('issue_status_id', 'o', nil)
    query.add_filter('issue_assigned_to_id', '=', [User.current.id.to_s])
    query.add_filter('user_id', '=', [User.current.id.to_s])
    query.add_filter('group_id', '=', ['0'])

    { query: query }
  end

  def self.async_load
    false
  end

  def self.show_placeholder
    false
  end

end

