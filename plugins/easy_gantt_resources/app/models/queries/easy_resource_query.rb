class EasyResourceQuery < Query
  include EasyGanttResources::ResourceQueryCommon

  VALID_PERIOD_OPERATORS = ['><', 't', 'w', 'm', 'y']

  def initialize(attributes=nil, *)
    super attributes

    defaults = EasySetting.value(:easy_gantt_resources_default_redmine_filters)
    if defaults.is_a?(Hash)
      defaults = defaults.with_indifferent_access
      from_params(defaults)
    else
      self.filters ||= {
        'issue_status_id' => { operator: 'o', values: [''] },
        'period' => { operator: 'm', values: [''] }
      }
    end
  end

  def entities(*args)
    issues(*args)
  end

  def from_params(params)
    build_from_params(params)
  end

  def to_params
    params = { set_filter: 1, type: self.class.name, f: [], op: {}, v: {} }

    filters.each do |filter_name, opts|
      params[:f] << filter_name
      params[:op][filter_name] = opts[:operator]
      params[:v][filter_name] = opts[:values]
    end

    params[:c] = column_names
    params
  end

  def to_partial_path
    'easy_gantt/easy_queries/show'
  end

  def default_columns_names
    [:subject, :priority]
  end

  def ensure_period_filter
    if has_filter?('period')
      # op = filters['period'][:operator]
      # unless VALID_PERIOD_OPERATORS.include?(op)
      #   filters['period'] = { operator: 'm', values: [] }
      # end
    else
      add_filter('period', 'm')
    end
  end

  def period
    @period ||= begin
      ensure_period_filter

      case operator_for('period')
      when '><'
        value = values_for('period')
        from = parse_date(value[0])
        to = parse_date(value[1])
      when 't'
        from = Date.today
        to = Date.today
      when 'w'
        first_day_of_week = l(:general_first_day_of_week).to_i
        day_of_week = Date.today.cwday

        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)

        from = Date.today - days_ago
        to = from + 6.days
      when 'm'
        from = Date.today.beginning_of_month
        to = Date.today.end_of_month
      when 'y'
        from = Date.today.beginning_of_year
        to = Date.today.end_of_year
      else
        # You should never go there
      end

      from ||= EasyGanttResources.default_resources_start_date
      to ||= EasyGanttResources.default_resources_end_date

      { from: from, to: to }
    end
  end

  def initialize_available_filters
    add_available_filter 'period', type: :date, name: l(:label_easy_gantt_period)

    @available_filters.merge! prefixed_available_filters(EasyResourceIssueQuery, 'issue')
    @available_filters.merge! prefixed_available_filters(EasyResourceUserQuery, 'user')

    if EasySetting.value(:easy_gantt_resources_show_groups)
      @available_filters.merge! prefixed_available_filters(EasyResourceGroupQuery, 'group')
    end

    # Remove conflict filters
    @available_filters.delete('issue_assigned_to_id')
    @available_filters.delete('issue_member_of_group')
    @available_filters.delete('issue_assigned_to_role')

    @available_filters
  end

  def prefixed_available_filters(query_klass, prefix)
    result = {}
    query = query_klass.new
    query.available_filters.each do |name, f|
      result["#{prefix}_#{name}"] = f
    end
    result
  end

  def available_columns
    @available_columns ||= [
      QueryColumn.new(:subject, sortable: "#{Issue.table_name}.subject"),
      QueryColumn.new(:priority, sortable: "#{IssuePriority.table_name}.position", default_order: 'desc', includes: [:priority]),
      QueryColumn.new(:assigned_to, sortable: lambda { User.fields_for_order_statement }, includes: [:assigned_to], preload: [:project => :enabled_modules])
    ]
  end

  def users
    result = []
    result.concat user_query.users(preload: :email_address)

    if EasySetting.value(:easy_gantt_resources_show_groups)
      result.concat group_query.groups
    end

    result
  end

  def user_query
    query = EasyResourceUserQuery.new(name: '_')
    query.filters = {}
    query.default_columns_names.clear

    filters.each do |name, f|
      if name.start_with?('user_')
        query.add_filter name.sub(/^user_/, ''), f[:operator], f[:values]
      end
    end

    query
  end

  def group_query
    query = EasyResourceGroupQuery.new(name: '_')
    query.filters = {}
    query.default_columns_names.clear

    filters.each do |name, f|
      if name.start_with?('group')
        query.add_filter name.sub(/^group/, ''), f[:operator], f[:values]
      end
    end

    query
  end

  def issues(*args)
    query = EasyResourceIssueQuery.new(name: '_')
    query.filters = {}
    query.project = project

    filters.each do |name, f|
      if name.start_with?('issue_')
        query.add_filter name.sub(/^issue_/, ''), f[:operator], f[:values]
      end
    end

    scope = query.entity_scope.joins(:project).
                               preload(:time_entries).
                               where(issues: { assigned_to_id: @assigned_to },
                                     projects: { status: Project::STATUS_ACTIVE }).
                               easy_gantt_resource_between(period[:from], period[:to])
                               # with_easy_gantt_resources(period[:from], period[:to])
    query.entity_scope = scope

    query.entities(*args)
  end

end
