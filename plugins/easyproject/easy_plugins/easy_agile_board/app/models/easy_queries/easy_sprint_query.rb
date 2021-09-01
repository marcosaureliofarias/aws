class EasySprintQuery < EasyQuery

  def initialize_available_columns
    group = l("label_filter_group_#{self.class.name.underscore}")
    add_available_column EasyQueryDateColumn.new(:start_date, title: EasySprint.human_attribute_name(:start_date), sortable: "#{EasySprint.table_name}.start_date", groupable: "#{EasySprint.table_name}.start_date", group: group)
    add_available_column EasyQueryDateColumn.new(:due_date, title: EasySprint.human_attribute_name(:due_date), sortable: "#{EasySprint.table_name}.due_date", groupable: "#{EasySprint.table_name}.due_date", group: group)
    add_available_column EasyQueryColumn.new(:project, title: EasySprint.human_attribute_name(:project), sortable: "#{Project.table_name}.name", groupable: "#{EasySprint.table_name}.project_id", group: group, joins: [:project])
    add_available_column EasyQueryColumn.new(:name, sortable: "#{EasySprint.table_name}.name", group: group)
    add_available_column EasyQueryColumn.new(:capacity, sortable: "#{EasySprint.table_name}.capacity", group: group, sumable: :both )
    add_available_column EasyQueryColumn.new(:version, title: EasySprint.human_attribute_name(:version), sortable: "#{Version.table_name}.name", groupable: "#{EasySprint.table_name}.version_id", group: group, includes: [:version])
    add_available_column EasyQueryColumn.new(:goal, sortable: "#{EasySprint.table_name}.goal", group: group, inline: false)
    add_available_column EasyQueryColumn.new(:closed, group: group)
    add_available_column EasyQueryColumn.new(:cross_project, group: group)
    [true, false].each do |closed_only|
      add_available_column EasyQueryParameterizedColumn.new(:"estimated_time_closed_#{closed_only}", arguments: closed_only, method: 'sum_estimated_time', title: l('field_sum_estimated_time_closed_' + closed_only.to_s), sumable: :both, sumable_sql: sum_of_column_sql_sum('estimated_hours', closed_only), group: group)
      add_available_column EasyQueryParameterizedColumn.new(:"story_points_closed_#{closed_only}", arguments: closed_only, method: 'sum_story_points', title: l('field_sum_story_points_closed_' + closed_only.to_s), sumable: :both, sumable_sql: sum_of_column_sql_sum('easy_story_points', closed_only), group: group)
    end
    [:backlog, :progress, :done].each do |phase|
      add_available_column EasyQueryParameterizedColumn.new(:"sum_issues_spent_time_#{phase.to_s}", arguments: ['spent_hours', phase], method: 'sum_issues_attribute',
title: l(phase.to_s, scope: 'easy_sprint.label_spent_time'), sumable: :both, sumable_sql: sum_of_column_by_phase_sql_sum('hours','issue_id', TimeEntry.table_name, phase), group: group)
      add_available_column EasyQueryParameterizedColumn.new(:"sum_issues_story_points_#{phase.to_s}", arguments: ['easy_story_points', phase], method: 'sum_issues_attribute', title: l(phase.to_s, scope: 'easy_sprint.label_easy_story_points'), sumable: :both, sumable_sql: sum_of_column_by_phase_sql_sum('easy_story_points','id', Issue.table_name, phase), group: group)
      add_available_column EasyQueryParameterizedColumn.new(:"sum_issues_estimated_time_#{phase.to_s}", arguments: ['estimated_hours', phase], method: 'sum_issues_attribute', title: l(phase.to_s, scope: 'easy_sprint.label_estimated_time'), sumable: :both, sumable_sql: sum_of_column_by_phase_sql_sum('estimated_hours','id', Issue.table_name, phase), group: group)
    end
    add_available_column EasyQueryParameterizedColumn.new(:"sum_issues_spent_time_#{'all'}", arguments: ['spent_hours', :all], method: 'sum_issues_attribute', title: l('all', scope: 'easy_sprint.label_spent_time'), sumable: :both, sumable_sql: sum_of_column_by_phase_sql_sum('hours','issue_id', TimeEntry.table_name, :all), group: group)
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'created_at', { type: :date_period, time_column: true }
      add_available_filter 'updated_at', { type: :date_period, time_column: true, label: :label_updated_within }
      add_available_filter 'start_date', { type: :date_period }
      add_available_filter 'due_date', { type: :date_period }
      add_available_filter 'closed', { type: :boolean, name: EasyEntityActivity.human_attribute_name(:closed) }
      add_available_filter 'cross_project', { type: :boolean, name: EasyEntityActivity.human_attribute_name(:cross_project) }
      add_available_filter 'goal', { type: :text, name: EasyEntityActivity.human_attribute_name(:goal) }
      add_available_filter 'capacity', { type: :integer, name: EasyEntityActivity.human_attribute_name(:capacity) }
      add_available_filter 'version_id', { type: :list_optional, values: proc { Version.values_for_select_with_project(Version.visible.where(projects: { easy_is_easy_template: false }).joins(:project)) } }
      unless project
        add_available_filter 'project_id', { type: :list_autocomplete, source: :visible_projects, source_root: :projects, order: 1, name: EasyEntityActivity.human_attribute_name(:project_id), data_type: :project }
      end
    end
  end

  def entity
    EasySprint
  end

  def self.permission_view_entities
    :view_easy_scrum_board
  end

  def self.chart_support?
    true
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = "#{EasySprint.table_name}.project_id = #{self.project_id}" if self.project
      @additional_statement_added = true
    end
    @additional_statement
  end

  def entity_easy_query_path(options = {})
    easy_sprints_path(options)
  end

  def default_list_columns
    super.presence || %w(name project start_time due_date)
  end

  def sql_status_closed
    " AND t.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{self.class.connection.quoted_true})"
  end

  def sum_of_column_sql_sum(column_name, only_closed)
    "(COALESCE((SELECT SUM(t.#{column_name}) FROM #{Issue.table_name} t WHERE t.easy_sprint_id = #{entity_table_name}.id#{only_closed ? sql_status_closed : ''}), 0))"
  end

  def relation_condition(relation_type)
    relation_phases = IssueEasySprintRelation::TYPES[relation_type]
    if relation_phases.is_a? Range
    " AND #{IssueEasySprintRelation.table_name}.relation_type BETWEEN #{relation_phases.first} AND #{relation_phases.last} "
    else
    " AND #{IssueEasySprintRelation.table_name}.relation_type = #{relation_phases}"
    end
  end

  def sum_of_column_by_phase_sql_sum(column_name, key, table_name, relation_type)
    "(COALESCE((SELECT SUM(t.#{column_name}) FROM #{table_name} t LEFT OUTER JOIN #{IssueEasySprintRelation.table_name} ON t.#{key} = #{IssueEasySprintRelation.table_name}.issue_id WHERE #{IssueEasySprintRelation.table_name}.easy_sprint_id = #{entity_table_name}.id#{relation_type != :all ? relation_condition(relation_type) : '' }), 0))"
  end

end

