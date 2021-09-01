class TestPlanQuery < EasyQuery

  self.queried_class = TestPlan

  def self.permission_view_entities
    :view_test_plans
  end

  def initialize_available_filters
    add_available_filter 'name', name: ::TestCase.human_attribute_name(:name), type: :string

    if project.nil?
      add_available_filter 'project_id', name: ::TestPlan.human_attribute_name(:project_id), type: :list_optional, values: all_projects_values
    end
    add_available_filter 'test_cases', {:type => :list_autocomplete, source: 'test_cases_autocomplete', autocomplete_options: { project_id: project_id }, :order => 5, :name => TestPlan.human_attribute_name(:test_cases)}

    add_available_filter 'author_id', name: ::TestPlan.human_attribute_name(:author_id), type: :list, values: proc { all_users_values(include_me: true) }

    add_custom_fields_filters(TestPlanCustomField)
  end

  def available_columns
    return @available_columns if @available_columns

    add_available_column 'name', title: ::TestPlan.human_attribute_name(:name), caption: ::TestPlan.human_attribute_name(:name), sortable: "#{TestPlan.table_name}.name", groupable: "#{TestPlan.table_name}.name"
    add_available_column 'project', title: ::TestPlan.human_attribute_name(:project_id), caption: ::TestPlan.human_attribute_name(:project_id), groupable: "#{TestPlan.table_name}.project_id", sortable: "sort_project.name", preload: [:project]
    add_available_column 'test_cases', title: ::TestPlan.human_attribute_name(:test_cases), caption: ::TestPlan.human_attribute_name(:test_cases), preload: [:test_cases]
    add_available_column 'author', title: ::TestPlan.human_attribute_name(:author_id), caption: ::TestPlan.human_attribute_name(:author_id), groupable: "#{TestPlan.table_name}.author_id", sortable: lambda { User.fields_for_order_statement('sort_author') }, preload: [:author]
    add_available_column EasyQueryDateColumn.new('created_at', title: ::TestPlan.human_attribute_name(:created_at), caption: ::TestPlan.human_attribute_name(:created_at), sortable: "#{TestPlan.table_name}.created_at")
    add_available_column EasyQueryDateColumn.new('updated_at', title: ::TestPlan.human_attribute_name(:updated_at), caption: ::TestPlan.human_attribute_name(:updated_at), sortable: "#{TestPlan.table_name}.updated_at")

    @available_columns += TestPlanCustomField.visible.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def default_columns_names
    super.presence || [:name, :project] #.flat_map{|c| [c.to_s, c.to_sym]}
  end

  def default_list_columns
    super.presence || %w(name project)
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = project_statement unless project_statement.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def project_statement
    return nil unless project
    "#{entity.table_name}.project_id = #{project.id}"
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

  def sql_for_test_cases_field(field, operator, value)
    op = operator.start_with?('!') ? 'NOT ' : ''
    arel = EasyEntityAssignment.arel_table
    conditions = arel[:entity_from_type].eq('TestPlan').and(arel[:entity_to_type].eq('TestCase'))
    conditions = conditions.and(arel[:entity_to_id].in(value)) unless operator.include?('*')
    sql = EasyEntityAssignment.where(conditions).to_sql
    "#{op}EXISTS (#{sql} AND #{arel.table_name}.entity_from_id = #{self.entity.table_name}.id)"
  end

  def outputs
    super.presence || %w(list)
  end

end
