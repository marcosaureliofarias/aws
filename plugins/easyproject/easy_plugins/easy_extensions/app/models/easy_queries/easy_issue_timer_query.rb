class EasyIssueTimerQuery < EasyQuery

  def query_after_initialize
    super
    self.display_show_sum_row = false
  end

  def self.permission_view_entities
    :view_issue_timers_of_others
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement       = project_statement unless project_statement.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def initialize_available_filters
    on_filter_group(l(:label_easy_issue_timer)) do
      add_principal_autocomplete_filter 'user_id', { order: 1 }
      add_available_filter 'user_group', { type: :list_optional, order:  2,
                                           name:   l(:field_group), values: proc { Group.sorted.visible.givable.map { |g| [g.name, g.id.to_s] } } }
      add_available_filter 'start', { type: :date_period, order: 3, name: l(:field_start_time) }
      add_available_filter 'paused_at', { type: :boolean, order: 4 }
    end

    on_filter_group(l(:label_filter_group_easy_issue_query)) do
      add_available_filter 'issue_priority_id', { type:   :list,
                                                  order:  2,
                                                  name:   l(:field_priority),
                                                  values: proc { IssuePriority.sorted.active.map { |s| [s.name, s.id.to_s] } } }

      add_available_filter 'issue_status_id', { type:   :list_status,
                                                order:  3,
                                                name:   l(:field_status),
                                                values: proc { IssueStatus.sorted.map { |s| [s.name, s.id.to_s] } } }

      unless project
        add_available_filter 'issue_project_id', { type:      :list_optional,
                                                   order:     1,
                                                   values:    proc { all_projects_values(include_mine: true) },
                                                   name:      l(:field_project),
                                                   data_type: :project }
      end
    end
  end

  def available_columns
    unless @available_columns_added
      group              = l(:label_easy_issue_timer)
      group_issue        = l(:label_filter_group_easy_issue_query)
      group_user         = l(:label_user_plural)
      @available_columns = [
          EasyQueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :groupable => true, :group => group),
          EasyQueryColumn.new(:user, :groupable => true, :sortable => lambda { User.fields_for_order_statement }, :group => group_user),
          EasyQueryColumn.new(:start, :sortable => "#{EasyIssueTimer.table_name}.start", :groupable => true, :caption => :field_start_time, :group => group),
          EasyQueryDateColumn.new(:paused_at, :sortable => "#{EasyIssueTimer.table_name}.paused_at", :groupable => false, :group => group),
          EasyQueryColumn.new(:issue_priority, :sortable => "#{IssuePriority.table_name}.position", :caption => :field_priority, :includes => [{ :issue => :priority }], :group => group_issue),
          EasyQueryColumn.new(:issue_status, :sortable => "#{IssueStatus.table_name}.position", :caption => :field_status, :includes => [{ :issue => :status }], :group => group_issue),
          EasyQueryColumn.new(:issue_project, :sortable => "#{Project.table_name}.name", :caption => :field_project, :groupable => "#{Project.table_name}.id", :group => group_issue),
          EasyQueryColumn.new(:current_hours, :numeric => true, :group => group)
      ]

      if User.current.allowed_to?(:view_estimated_hours, project, { :global => true })
        @available_columns << EasyQueryColumn.new(:issue_estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :caption => :field_estimated_hours, :numeric => true, :group => group)
      end

      @available_columns_added = true
    end
    @available_columns
  end

  def default_list_columns
    super.presence || ['issue', 'user', 'paused_at', 'current_hours', 'view_estimated_hours']
  end

  def project=(project)
    @available_filters = nil # reset cached filters on project change
    super
  end

  def entity
    EasyIssueTimer
  end

  def default_find_include
    [:user, :issue]
  end

  def project_statement
    "#{Project.table_name}.id = %d" % self.project.id if self.project
  end

  def sql_for_user_group_field(field, operator, value)
    if operator == '*' # Any group
      groups   = Group.givable
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      groups   = Group.givable
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value)
    end

    members_of_groups = groups.joins(:users).distinct.pluck('users_users.id')

    sql = '(' + sql_for_field('user_id', operator, members_of_groups, EasyIssueTimer.table_name, 'user_id', false) + ')'
    sql
  end

  def get_custom_sql_for_field(field, operator, value)
    if field.start_with?('issue_')
      db_table = Issue.table_name
      db_field = field.sub('issue_', '')
      if db_field == 'project_id' && !value.blank? && value.delete('mine')
        value.concat(User.current.memberships.map(&:project_id).map(&:to_s))
      end
      returned_sql_for_field = self.sql_for_field(field, operator, value, db_table, db_field)
      return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
    end
  end

  def sql_for_paused_at_field(field, operator, value)
    val = (value.first.to_i == 0) ? 'IS' : 'IS NOT'
    "(#{EasyIssueTimer.table_name}.paused_at #{val} NULL)"
  end

  def entity_easy_query_path(options)
    nil
  end

  def self.report_support?
    false
  end

end
