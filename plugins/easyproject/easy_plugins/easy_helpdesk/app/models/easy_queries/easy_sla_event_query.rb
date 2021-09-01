class EasySlaEventQuery < EasyQuery

  def entity
    EasySlaEvent
  end

  def self.permission_view_entities
    :view_easy_sla_events
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', name: EasySlaEvent.human_attribute_name(:name), type: :string
      add_available_filter 'occurence_time', name: EasySlaEvent.human_attribute_name(:occurence_time), type: :date_period
      add_available_filter 'issue_id', name: EasySlaEvent.human_attribute_name(:issue), type: :list_autocomplete,
                           source: 'easy_sla_event_issues', source_root: 'entities', source_options: { project_id: project&.id }
      add_available_filter 'issue_status_id',
                           type: :list,
                           name: l(:label_issue_status),
                           values: -> { IssueStatus.sorted.collect { |status| [status.name, status.id.to_s] } }
      add_principal_autocomplete_filter 'user_id', name: EasySlaEvent.human_attribute_name(:user)

      unless User.current.hide_sla_data?
        add_available_filter 'sla_response', name: EasySlaEvent.human_attribute_name(:sla_response), type: :date_period
        add_available_filter 'sla_resolve', name: EasySlaEvent.human_attribute_name(:sla_resolve), type: :date_period
      end

      add_available_filter 'first_response', name: EasySlaEvent.human_attribute_name(:first_response), type: :float
      add_available_filter 'sla_response_fulfilment', name: EasySlaEvent.human_attribute_name(:sla_response_fulfilment), type: :float
      add_available_filter 'sla_resolve_fulfilment', name: EasySlaEvent.human_attribute_name(:sla_resolve_fulfilment), type: :float

      if project.nil?
        add_available_filter 'project_id', { type: :list_autocomplete, source: 'visible_projects', source_root: 'projects' }
        add_available_filter 'subprojects_of',
                              type:      :list,
                              name:      "#{l(:field_subprojects_of)} (#{l('easy_query.name.easy_project_query')})",
                              values:    -> { all_projects_parents_values },
                              data_type: :project,
                              includes:  [:project]
      end

      add_available_filter 'created_at', name: EasySlaEvent.human_attribute_name(:created_at), type: :date_period
      add_available_filter 'updated_at', name: EasySlaEvent.human_attribute_name(:updated_at), type: :date_period
    end

    add_associations_filters EasyIssueQuery
  end

  def initialize_available_columns
    group = l("label_filter_group_#{self.class.name.underscore}")

    on_column_group(default_group_label) do
      add_available_column 'name', title: EasySlaEvent.human_attribute_name(:name)
      add_available_column EasyQueryDateColumn.new('occurence_time', title: EasySlaEvent.human_attribute_name(:occurence_time), groupable: true, sortable: "#{ EasySlaEvent.table_name }.occurence_time")
      add_available_column 'issue', title: EasySlaEvent.human_attribute_name(:issue), sortable: "#{ Issue.table_name }.subject", groupable: "#{ EasySlaEvent.table_name }.issue_id", includes: [:issue]
      add_available_column 'issue_status', title: l(:label_issue_status), sortable: "#{ IssueStatus.table_name }.name", groupable: "#{ EasySlaEvent.table_name }.issue_status_id", includes: [:issue_status]
      add_available_column 'user', title: EasySlaEvent.human_attribute_name(:user), sortable: lambda { User.fields_for_order_statement }, groupable: "#{ EasySlaEvent.table_name }.user_id", includes: [:user]
      add_available_column 'occurence_time', title: EasySlaEvent.human_attribute_name(:occurence_time)
      unless User.current.hide_sla_data?
        add_available_column 'sla_response', title: EasySlaEvent.human_attribute_name(:sla_response)
        add_available_column 'sla_resolve', title: EasySlaEvent.human_attribute_name(:sla_resolve)
      end
      add_available_column 'first_response', title: EasySlaEvent.human_attribute_name(:first_response), sortable: "#{ EasySlaEvent.table_name }.first_response", sumable: :both
      add_available_column 'sla_response_fulfilment', title: EasySlaEvent.human_attribute_name(:sla_response_fulfilment), groupable: true, sortable: "#{ EasySlaEvent.table_name }.sla_response_fulfilment", sumable: :both
      add_available_column 'sla_resolve_fulfilment', title: EasySlaEvent.human_attribute_name(:sla_resolve_fulfilment), groupable: true, sortable: "#{ EasySlaEvent.table_name }.sla_resolve_fulfilment", sumable: :both
      add_available_column 'project', title: EasySlaEvent.human_attribute_name(:project), sortable: "#{ Project.table_name }.name", groupable: "#{ EasySlaEvent.table_name }.project_id", joins: [:project]
      add_available_column EasyQueryDateColumn.new('created_at', title: EasySlaEvent.human_attribute_name(:created_at), sortable: "#{ EasySlaEvent.table_name }.created_at", groupable: true)
      add_available_column EasyQueryDateColumn.new('updated_at', title: EasySlaEvent.human_attribute_name(:updated_at), sortable: "#{ EasySlaEvent.table_name }.updated_at", groupable: true)
    end

    add_associated_columns EasyIssueQuery
    @available_columns
  end

  def default_list_columns
    super.presence || ['name', 'occurence_time', 'issue', 'user', 'project']
  end

  def self.chart_support?
    true
  end

  def sql_for_subprojects_of_field(field, operator, value)
    values = Array.wrap(value)
    op = operator == '='

    projects_tree = Project.where(id: values).pluck(:lft, :rgt)

    return '1=0' if projects_tree.blank?

    projects_tree.map! do |lft_rgt|
      op ? "projects.lft >= #{lft_rgt[0]} AND projects.rgt <= #{lft_rgt[1]}" : "projects.lft < #{lft_rgt[0]} OR projects.rgt > #{lft_rgt[1]}"
    end

    '(' + projects_tree.join(" ) #{op ? 'OR' : 'AND'} ( ") + ')'
  end

end
