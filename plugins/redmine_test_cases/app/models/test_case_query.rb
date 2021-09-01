class TestCaseQuery < EasyQuery

  self.queried_class = TestCase

  def self.permission_view_entities
    :view_test_cases
  end

  def initialize_available_filters
    include_groups = Setting.issue_group_assignment? || nil

    on_filter_group(default_group_label) do
      add_available_filter 'id', name: ::TestCase.human_attribute_name(:id), type: :integer
      add_available_filter 'name', name: ::TestCase.human_attribute_name(:name), type: :string
      add_available_filter 'scenario', name: ::TestCase.human_attribute_name(:scenario), type: :text
      add_available_filter 'author_id', name: ::TestCase.human_attribute_name(:author_id), type: :list, values: proc { all_users_values(include_me: true) }

      add_available_filter 'issues', {:type => :list_autocomplete, source: 'issues_autocomplete', autocomplete_options: { project_id: project_id }, :order => 5, :name => EasyEntityActivity.human_attribute_name(:issues)}

      add_available_filter 'test_plans', type: :list_autocomplete, source: 'test_plans_autocomplete', autocomplete_options: { project_id: project_id }, name: TestCase.human_attribute_name(:test_plans)

      if project.nil?
        add_available_filter 'project_id', { type: :list_optional, joins: [:project], values: proc { all_projects_values(include_mine: true) }, data_type: :project }
      end

      add_available_filter 'created_at', name: ::TestCase.human_attribute_name(:created_at), type: :date_period, time_column: true
      add_available_filter 'updated_at', name: ::TestCase.human_attribute_name(:updated_at), type: :date_period, time_column: true
    end

    add_associations_filters EasyProjectQuery, only: ['is_public', 'name', 'easy_start_date', 'easy_due_date', 'created_on', 'author_id', 'easy_priority_id']

    on_filter_group(l(:label_filter_group_easy_issue_query)) do
      add_available_filter 'issues.subject', { type: :text, attr_reader: true, includes: :issues, name: l(:field_subject) }
      add_available_filter 'issues.start_date', { type: :date_period, time_column: false, includes: :issues, name: l(:field_start_date) }
      add_available_filter 'issues.due_date', { type: :date_period, time_column: false, includes: :issues, name: l(:field_due_date) }
      add_available_filter 'issues.created_on', { type: :date_period, time_column: true, includes: :issues, name: l(:field_created_on) }
      add_available_filter 'issues.author_id', { type: :list, values: proc { all_users_values }, includes: :issues, name: l(:field_author) }
      add_available_filter 'issues.done_ratio', { type: :integer, attr_reader: true, attr_writer: true, includes: :issues, name: l(:field_done_ratio) }
      add_available_filter 'issues.status_id', { type: :list_status, joins: [ issues: [:status]], includes: :issues, attr_reader: true, attr_writer: true, values: proc { IssueStatus.sorted.map { |s| [s.name, s.id.to_s] } }, name: l(:field_status) }
      add_available_filter 'issues.priority_id', { type: :list, includes: :issues, values: proc { IssuePriority.active.sorted.map { |s| [s.name, s.id.to_s] } }, name: l(:field_priority) }

      if User.current.allowed_to?(:view_estimated_hours, project, global: true)
        add_available_filter 'issues.estimated_hours', { type: :float, attr_reader: true, attr_writer: true, includes: :issues, name: l(:field_estimated_hours) }
      end

      add_principal_autocomplete_filter 'issues.assigned_to_id', { type: :list, values: proc { all_users_values }, includes: :issues, name: l(:field_assigned_to) }
    end

    add_custom_fields_filters(TestCaseCustomField)

    # Issue custom fields
    if project
      add_custom_fields_filters(project.all_issue_custom_fields)
    else
      add_custom_fields_filters(IssueCustomField)
    end

    # Others custom fields
    add_associations_custom_fields_filters :project, :author

  end

  def available_columns
    return @available_columns if @available_columns

    add_available_column 'id', title: ::TestCase.human_attribute_name(:id), caption: ::TestCase.human_attribute_name(:id), sortable: "#{TestCase.table_name}.id", groupable: "#{TestCase.table_name}.id"
    add_available_column 'name', title: ::TestCase.human_attribute_name(:name), caption: ::TestCase.human_attribute_name(:name), sortable: "#{TestCase.table_name}.name", groupable: "#{TestCase.table_name}.name"
    add_available_column 'scenario', title: ::TestCase.human_attribute_name(:scenario), caption: ::TestCase.human_attribute_name(:scenario), sortable: "#{TestCase.table_name}.scenario"
    add_available_column 'project', title: ::TestCase.human_attribute_name(:project_id), caption: ::TestCase.human_attribute_name(:project_id), groupable: "#{TestCase.table_name}.project_id", sortable: "sort_project.name", preload: [:project]
    add_available_column 'issues', title: ::TestCase.human_attribute_name(:issues), caption: ::TestCase.human_attribute_name(:issues), preload: [:issues]
    add_available_column 'author', title: ::TestCase.human_attribute_name(:author_id), caption: ::TestCase.human_attribute_name(:author_id), groupable: "#{TestCase.table_name}.author_id", sortable: lambda { User.fields_for_order_statement('sort_author') }, preload: [:author]
    add_available_column 'test_plans', title: ::TestCase.human_attribute_name(:test_plans), caption: ::TestCase.human_attribute_name(:test_plans), preload: [:test_plans]
    add_available_column EasyQueryDateColumn.new('created_at', title: ::TestCase.human_attribute_name(:created_at), caption: ::TestCase.human_attribute_name(:created_at), sortable: "#{TestCase.table_name}.created_at")
    add_available_column EasyQueryDateColumn.new('updated_at', title: ::TestCase.human_attribute_name(:updated_at), caption: ::TestCase.human_attribute_name(:updated_at), sortable: "#{TestCase.table_name}.updated_at")

    @available_columns += TestCaseCustomField.visible.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def default_columns_names
    super.presence || [:id, :name, :scenario, :project] #.flat_map{|c| [c.to_s, c.to_sym]}
  end

  def default_list_columns
    super.presence || %w(id name scenario project)
  end

  #
  # def entity_scope
  #   super || project && project.test_cases.visible || TestCase.visible
  # end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = project_statement unless project_statement.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('sort_author')
        joins << "LEFT OUTER JOIN #{User.table_name} sort_author ON sort_author.id = #{self.entity_table_name}.author_id"
      end
      if order_options.include?('project')
        joins << "LEFT OUTER JOIN #{Project.table_name} sort_project ON sort_project.id = #{self.entity_table_name}.project_id"
      end
    end
    joins
  end

  def project_statement
    return nil unless project

    if try(:force_current_project_filter)
      "#{entity.table_name}.project_id = #{project.id}"
    elsif Setting.display_subprojects_issues?
      project_clauses = []
      ids = [project.id]
      if Project.column_names.include?('easy_is_easy_template')
        if project.easy_is_easy_template?
          ids.concat(project.descendants.templates.pluck(:id))
        else
          ids.concat(project.descendants.non_templates.pluck(:id))
        end
      else
        ids.concat(project.descendants.pluck(:id))
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
      project_clauses.any? ? project_clauses.join(' AND ') : nil
    else
      "#{entity.table_name}.project_id = #{project.id}"
    end

  end

  def outputs
    super.presence || %w(list)
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def sql_for_issues_field(field, operator, value)
    op = operator.start_with?('!') ? 'NOT ' : ''
    arel = EasyEntityAssignment.arel_table
    conditions = arel[:entity_from_type].eq('Issue').and(arel[:entity_to_type].eq('TestCase'))
    conditions = conditions.and(arel[:entity_from_id].in(value)) unless operator.include?('*')
    sql = EasyEntityAssignment.where(conditions).to_sql
    "#{op}EXISTS (#{sql} AND #{arel.table_name}.entity_to_id = #{self.entity.table_name}.id)"
  end

  def sql_for_test_plans_field(field, operator, value)
    o = operator == '=' ? 'IN' : 'NOT IN'
    values = TestCase.includes(:test_plans).where(test_plans: {id: Array(value)}).pluck(:id)
    values.any? && "(#{entity_table_name}.id #{o} (#{values.join(',')}))" || nil
  end

end
