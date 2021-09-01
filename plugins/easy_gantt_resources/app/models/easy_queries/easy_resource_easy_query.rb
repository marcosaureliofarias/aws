class EasyResourceEasyQuery < EasyQuery
  include EasyGanttResources::ResourceQueryCommon

  def self.permission_view_entities
    :view_easy_resources
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

  def entity
    Issue
  end

  def default_list_columns
    super.presence || ['subject', 'priority']
  end

  def groupable_columns
    []
  end

  def sumable_columns
    []
  end

  def available_outputs
    ['list']
  end

  def entities(*args)
    issues(*args)
  end

  def table_support?
    false
  end

  def display_entity_count?
    false
  end

  def entity_count(*)
    0
  end

  def columns_with_me
    super + ['user_id']
  end

  # def to_partial_path
  #   'easy_resource_easy_queries/easy_query'
  # end

  def to_partial_path
    'easy_queries/easy_query_index'
  end

  def ensure_period_filter
    return if has_filter?('period')
    add_filter('period', 'date_period_1', 'period' => 'last30_next90')
  end

  def period
    @period ||= begin
      ensure_period_filter
      value = values_for('period')
      op = operator_for('period').last

      if op == '1'
        if value['period'] == 'from_m_to_n_days'
          range = get_date_range(
              '1',                   # period_type
              value['period'],       # period
              value['from'],         # from
              value['to'],           # to
              0,                     # period_days
              value['period_days2'], # period_days_from
              value['period_days']   # period_days_to
            )
        else
          range = get_date_range(
              op,                        # period_type
              value['period'],           # period
              value['from'],             # from
              value['to'],               # to
              value['period_days'],      # period_days
              value['period_days_from'], # period_days_from
              value['period_days_to']    # period_days_to
            )
        end
      elsif op == '2'
        range = get_date_range(op, 'all', value['from'], value['to'])
      end

      if !range.is_a?(Hash) || range[:from].nil? || range[:to].nil?
        # Not very nice but if period is invalid first option on select is yesterday
        # This is only for consistency
        range = { from: Date.yesterday, to: Date.yesterday }
      end

      range
    end
  end

  def default_filter
    super.presence || {
      'period' => { operator: 'date_period_1', values: { 'from' => '', 'to' => '', 'period' => 'last30_next90' } },
      'issue_status_id' => { operator: 'o', values: ['1'] },
      'user_status' => { operator: '=', values: [User::STATUS_ACTIVE.to_s] }
    }
  end

  def query_after_initialize
    super

    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index = false
    self.display_filter_settings_on_index = false

    self.display_filter_group_by_on_edit = false
    self.display_filter_sort_on_edit = false
    self.display_filter_settings_on_edit = false

    self.display_show_sum_row = false
    self.display_load_groups_opened = false
    self.display_outputs_select_on_index = false

    self.export_formats = {}
    self.is_tagged = true if new_record?
    self.display_filter_fullscreen_button = false
    self.easy_query_entity_controller = 'easy_gantt_resources'
    self.display_project_column_if_project_missing = false
  end

  def basic_filters
    { 'period' => { type: :date_period,
                    time_column: false,
                    order: 1,
                    name: l(:label_easy_gantt_period),
                    group: l(:label_easy_gantt_allocations) } }
  end

  def extended_period_options
    { option_limit: { next_week: ['period'],
                      tomorrow: ['period'],
                      next_7_days: ['period'],
                      next_30_days: ['period'],
                      next_90_days: ['period'],
                      next_month: ['period'],
                      next_year: ['period'] },
      disabled_values: ['all', 'is_null', 'is_not_null'] }
  end

  def filter_groups_ordering
    [
      l(:label_most_used),
      l(:label_filter_group_easy_issue_query),
      EasyQuery.column_filter_group_name(nil),
      l(:label_filter_group_relations),
      l(:label_filter_group_easy_user_query),
      EasyQuery.column_filter_group_name(:assigned_to),
      l(:label_filter_group_easy_group_query),
      l(:label_filter_group_easy_project_query),
      EasyQuery.column_filter_group_name(:project),
      l(:label_filter_group_status_time),
      l(:label_filter_group_status_count)
    ]
  end

  def column_groups_ordering
    [
      l(:label_most_used),
      l(:label_filter_group_easy_issue_query),
      EasyQuery.column_filter_group_name(nil),
      l(:label_filter_group_easy_project_query),
      EasyQuery.column_filter_group_name(:project),
      l(:label_filter_group_easy_time_entry_query),
      l(:label_user_plural)
    ]
  end

  def column_groups_ordering
    @column_groups_ordering ||= EasyGanttEasyIssueQuery.new.column_groups_ordering
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = {}
    @available_filters.merge! basic_filters
    @available_filters.merge! prefixed_available_filters(EasyIssueQuery, 'issue')
    @available_filters.merge! prefixed_available_filters(EasyUserQuery, 'user')

    # User selection
    add_principal_autocomplete_filter('user_id',
                                      source_options: { internal_non_system: true },
                                      group: l(:label_filter_group_easy_user_query),
                                      name: l(:label_easy_gantt_resources_users_selection),
                                      klass: User)

    # Group selection
    if EasySetting.value(:easy_gantt_resources_show_groups)
      @available_filters.merge! prefixed_available_filters(EasyGroupQuery, 'group')

      group_id_values = proc {
        Group.givable.active.non_system_flag.sorted.map{|g| [g.name, g.id.to_s] }
      }

      @available_filters['group_id'] = {
        type: :list_optional,
        order: 1,
        values: group_id_values,
        group: l(:label_filter_group_easy_group_query),
        name: l(:label_easy_gantt_resources_groups_selection)
      }
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
    query.filters_for_select.each do |name, f|
      result["#{prefix}_#{name}"] = f
      result["#{prefix}_#{name}"][:name] ||= I18n.translate("field_#{name.gsub(/_id$/, '')}")
    end
    result
  end

  def user_filters
    available_filters.select{|name, _| name.start_with?('user_') }
  end

  def issue_filters
    available_filters.select{|name, _| name.start_with?('issue_') }
  end

  def group_filters
    available_filters.select{|name, _| name.start_with?('group_') }
  end

  def available_columns
    @available_columns ||= EasyGanttEasyIssueQuery.new.available_columns
  end

  def issues(*args)
    issue_scope = Issue.visible.
                        preload(:time_entries).
                        where(issues: { assigned_to_id: @assigned_to },
                              projects: { easy_is_easy_template: false }).
                        where.not(projects: { status: [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED] }).
                        easy_gantt_resource_between(period[:from], period[:to])

    if Project.column_names.include?('easy_baseline_for_id')
      issue_scope = issue_scope.where(projects: { easy_baseline_for_id: nil })
    end

    issue_query = EasyIssueQuery.new
    issue_query.filters = {}
    issue_query.project = project
    issue_query.entity_scope = issue_scope
    filters.each do |name, f|
      if name =~ /^issue_/
        issue_query.add_filter name.gsub(/^issue_/, ''), f[:operator], f[:values]
      end
    end

    issue_query.entities(*args)
  end

  def user_query
    query = EasyUserQuery.new
    query.filters = {}
    query.default_list_columns.clear
    filters.each do |name, f|
      if name =~ /^user_/
        query.add_filter name.gsub(/^user_/, ''), f[:operator], f[:values]
        query.add_filter 'easy_system_flag', '=', '0'
        if name == 'user_id'
          query.add_additional_statement(sql_for_field('id', f[:operator], f[:values].map{|v| v == 'me' ? User.current.id.to_s : v}, User.table_name, 'id'))
        end
      end
    end
    query.add_filter('easy_user_type', '=', EasyUserType.easy_type_internal.pluck(:id).map(&:to_s)) unless filters.has_key?('user_easy_user_type')

    query
  end

  def group_query
    query = EasyGroupQuery.new
    query.entity_scope = Group.givable
    query.filters = {}
    query.default_list_columns.clear

    filters.each do |name, f|
      next unless name.start_with?('group_')

      if name == 'group_id'
        query.add_additional_statement(sql_for_field('id', f[:operator], f[:values], Group.table_name, 'id'))
      else
        query.add_filter name.sub(/^group_/, ''), f[:operator], f[:values]
      end
    end

    query
  end

  def users(options={})
    result = []
    result.concat user_query.entities(order: User.fields_for_order_statement.join(', '), preload: :easy_avatar)
    if EasySetting.value(:easy_gantt_resources_show_groups)
      result.concat group_query.entities(order: Group.fields_for_order_statement.join(', '), preload: :easy_avatar)
    end
    result
  end

  def entity_easy_query_path(options)
    {
      controller: easy_query_entity_controller,
      action: easy_query_entity_action,
      query_id: self
    }.merge(options.except(:project))
  end

end
