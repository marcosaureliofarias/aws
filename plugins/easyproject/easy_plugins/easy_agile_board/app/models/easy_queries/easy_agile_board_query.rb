class EasyAgileBoardQuery < EasyIssueQuery

  attr_accessor :easy_sprint, :only_assigned

  def query_after_initialize
    super
    self.display_filter_columns_on_index  = false
    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index     = false
    self.display_filter_columns_on_edit   = false
    self.display_filter_group_by_on_edit  = false
    self.display_filter_sort_on_edit      = false
    self.require_is_tagged                = true
    self.export_formats                   = {}
    self.easy_query_entity_controller     = 'easy_agile_board'
    self.easy_query_entity_action         = 'backlog'
  end

  def initialize_available_filters
    super
    on_filter_group(default_group_label) do
      add_available_filter 'category_id', { type: :list_optional, values: proc { (project ? project.issue_categories : IssueCategory).reorder(:name).pluck(:name, :id) } }
      add_available_filter 'priority_id', { type: :list, most_used: true, values: proc { IssuePriority.active.reorder(position: :desc).map {|s| [s.name, s.id.to_s] } } }
    end

    # only open milestones on scrum
    on_filter_group(l(:label_filter_group_easy_version_query)) do
      if project
        add_available_filter 'fixed_version_id', { type: :list_version, includes: [:fixed_version], values: proc {
          Version.values_for_select_with_project(project.shared_versions.open_and_locked)
        } }
      else
        # Global filters for cross project issue list
        add_available_filter 'fixed_version_id', { type: :list_version, includes: [:fixed_version], values: proc {
          Version.values_for_select_with_project(Version.open_and_locked.visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        } }
      end
    end
  end

  def initialize_available_columns
    super
    @available_columns << EasyQueryParameterizedColumn.new(
        :kanban_phase,
        arguments: self.project,
        method: 'kanban_phase',
        sortable: ["#{EasyKanbanIssue.quoted_table_name}.#{quote_column_name('phase')}", "#{EasyKanbanIssue.quoted_table_name}.#{quote_column_name('position')}"],
        groupable: "#{EasyKanbanIssue.quoted_table_name}.#{quote_column_name('phase')}",
        preload: [:easy_kanban_issues],
        includes: [:easy_kanban_issues]
    )
    @available_columns << EasyQueryColumn.new(
        :scrum_phase,
        sortable: ["#{IssueEasySprintRelation.quoted_table_name}.#{quote_column_name('relation_type')}", "#{IssueEasySprintRelation.quoted_table_name}.#{quote_column_name('position')}"],
        groupable: "#{IssueEasySprintRelation.quoted_table_name}.#{quote_column_name('relation_type')}",
        preload: [:issue_easy_sprint_relation],
        includes: [:issue_easy_sprint_relation]
    )
    @available_columns << EasyQueryColumn.new(:scrum_backlog, sortable: "#{EasyAgileBacklogRelation.quoted_table_name}.#{quote_column_name('project_id')}", groupable: true, preload: [:issue_easy_sprint_relation], includes: [:issue_easy_sprint_relation])
  end

  def searchable_columns
    id_column = "#{Issue.table_name}.id"
    id_column = "CAST(#{id_column} AS TEXT)" if Redmine::Database.postgresql?

    super << id_column
  end

  # disable searching in custom_fields
  def statement_for_searching
    self.searchable_columns.collect { |column| "(#{Redmine::Database.like(column, '?')})" }
  end

  def entity_easy_query_path(options)
    options = options.dup

    if (p = options.delete(:project) || self.project)
      if options.delete(:scrum_backlog).present?
        easy_agile_board_backlog_path(p, options)
      elsif options.delete(:kanban_backlog).present?
        project_easy_kanban_backlog_path(p, options)
      else
        easy_agile_board_path(p, options)
      end
    else
      nil
    end
  end

  def self.no_params_url_support?
    false
  end

  def to_params
    params = super
    params[:easy_sprint_id] = easy_sprint.to_param
    params[:only_assigned] = only_assigned ? '1' : '0'
    params
  end

  def from_params(params)
    super
    self.easy_sprint = EasySprint.find(params[:easy_sprint_id]) if params && params[:easy_sprint_id]
    self.only_assigned = params[:only_assigned].to_s.to_boolean
  end

  def self.chart_support?
    false
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

  def available_assigned_to_id_additional_statement
    if project
      members = Member.arel_table
      roles = Role.arel_table
      project_roles = Role.joins(:members).where(members[:project_id].eq(project.id)).distinct
      role_ids = project_roles.select{|r| r.allowed_to?(:add_issues) || r.assignable }.map(&:id)
      values = Principal.joins(members: :roles).where(members[:project_id].eq(project.id)).where(roles[:id].in(role_ids)).pluck(:id)

      Principal.arel_table[:id].in(values).to_sql
    else
      '1=1'
    end
  end
end
