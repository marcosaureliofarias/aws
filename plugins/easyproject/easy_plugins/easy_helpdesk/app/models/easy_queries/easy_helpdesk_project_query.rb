class EasyHelpdeskProjectQuery < EasyQuery

  def initialize_available_filters
    add_principal_autocomplete_filter 'assigned_to_id', { klass: User, order: 3 }

    on_filter_group(default_group_label) do
      add_available_filter 'project_id', { type: :list_autocomplete, order: 1, source: 'visible_projects', source_root: 'projects' }
      add_available_filter 'tracker_id', { type: :list, order: 2, values: Proc.new { Tracker.order(:position).all.collect { |s| [s.name, s.id.to_s] } }, includes: [:tracker] }
      add_available_filter 'default_for_mailbox_id', { type: :list, order: 4,
                                                       values: Proc.new { EasyRakeTaskEasyHelpdeskReceiveMail.includes(:default_for_helpdesk_project).collect { |t| [t.username_caption.to_s.strip, t.id.to_s] } } }
      add_available_filter 'monthly_hours', { type: :float, order: 5 }
      add_available_filter 'aggregated_hours', { type: :boolean, order: 6 }
      add_available_filter 'aggregated_hours_remaining', { type: :float, order: 7, label: :label_easy_helpdesk_actual_budget }
      add_available_filter 'monitor_due_date', { type: :boolean, order: 8 }
      add_available_filter 'monitor_spent_time', { type: :boolean, order: 9 }
    end

    add_associations_custom_fields_filters :project
  end

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column 'project', sortable: "#{Project.table_name}.name", includes: [:project]
      add_available_column 'tracker', sortable: "#{Tracker.table_name}.name", includes: [:tracker]
      add_available_column 'matching_emails', caption: :'field_easy_helpdesk_project_matching.domain_name'
      add_available_column 'monthly_hours', sortable: "#{EasyHelpdeskProject.table_name}.monthly_hours", sumable: :bottom
      add_available_column 'aggregated_hours', sortable: "#{EasyHelpdeskProject.table_name}.aggregated_hours"
      add_available_column 'aggregated_hours_remaining', sortable: "#{EasyHelpdeskProject.table_name}.aggregated_hours_remaining", caption: :label_easy_helpdesk_actual_budget, numeric: true
      add_available_column 'aggregated_from_last_period', caption: :label_easy_helpdesk_aggregated_from_last_period, numeric: true
      add_available_column 'remaining_hours', caption: :field_aggregated_hours_remaining, numeric: true
      add_available_column 'default_for_mailbox'
      add_available_column 'monitor_due_date', sortable: "#{EasyHelpdeskProject.table_name}.monitor_due_date"
      add_available_column 'monitor_spent_time', sortable: "#{EasyHelpdeskProject.table_name}.monitor_spent_time"
      add_available_column 'spent_time_last_month', caption: :field_easy_helpdesk_project_spent_time_last_month, numeric: true
      add_available_column 'spent_time_current_month', caption: :field_easy_helpdesk_project_spent_time_current_month, numeric: true
    end

    on_column_group(l('label_user_plural')) do
      add_available_column 'assigned_to', sortable: lambda{User.fields_for_order_statement}, includes: [:assigned_to]
      add_available_column 'watchers_ids', caption: :label_issue_watchers
    end

    add_associated_columns(EasyProjectQuery, association_name: :project)
  end

  def entity
    EasyHelpdeskProject
  end

  def default_find_include
    [:project, :tracker, :assigned_to, :easy_helpdesk_project_matching, :default_for_mailbox]
  end

  def searchable_columns
    ["#{Project.table_name}.name", "#{User.table_name}.firstname", "#{User.table_name}.lastname", "#{EasyHelpdeskProjectMatching.table_name}.domain_name"]
  end

  def entity_easy_query_path(options = {})
    easy_helpdesk_projects_path(options)
  end

  def self.chart_support?
    true
  end

  def joins_for_order_statement(order_options, return_type = :sql, uniq = true)
    joins = []

    if order_options
      joins.concat(EasyProjectQuery.new.project_order_joins(order_options))
      joins.concat(super(order_options, :array, uniq))
    end

    case return_type
    when :sql
      joins.any? ? joins.join(' ') : nil
    when :array
      joins
    else
      raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

  protected

  def sql_for_matching_emails_field(field, operator, value)
    db_table = EasyHelpdeskProjectMatching.table_name
    db_field = 'domain_name'
    sql = "#{EasyHelpdeskProject.table_name}.id IN (SELECT #{db_table}.easy_helpdesk_project_id FROM #{db_table} WHERE "
    sql << sql_for_field(field, operator, value, db_table, db_field) + ')'
    return sql
  end

end
