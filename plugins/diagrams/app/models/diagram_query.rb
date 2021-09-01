class DiagramQuery < EasyQuery
  self.queried_class = Diagram

  def initialize_available_filters
    add_available_filter 'title', name: ::Diagram.human_attribute_name(:title), type: :string

    if project.nil?
      add_available_filter 'project_id', name: ::Diagram.human_attribute_name(:project), type: :list_optional, values: all_projects_values
    end

    add_available_filter 'author_id', name: ::Diagram.human_attribute_name(:author_id), type: :list, values: proc { all_users_values(include_me: true) }
    add_available_filter 'created_at', name: ::Diagram.human_attribute_name(:created_at), type: :date
    add_available_filter 'updated_at', name: ::Diagram.human_attribute_name(:updated_at), type: :date
  end

  def initialize_available_columns
    return @available_columns if @available_columns

    add_available_column 'title', title: ::Diagram.human_attribute_name(:title), caption: ::Diagram.human_attribute_name(:title), sortable: "#{Diagram.table_name}.title", groupable: "#{Diagram.table_name}.title"
    add_available_column 'project', title: ::Diagram.human_attribute_name(:project_id), caption: ::Diagram.human_attribute_name(:project_id), groupable: "#{Diagram.table_name}.project_id", sortable: "projects.name", preload: [:project]
    add_available_column 'author', title: ::Diagram.human_attribute_name(:author_id), caption: ::Diagram.human_attribute_name(:author_id), groupable: "#{Diagram.table_name}.author_id", sortable: lambda { User.fields_for_order_statement('sort_author') }, preload: [:author]
    add_available_column EasyQueryDateColumn.new('created_at', title: ::Diagram.human_attribute_name(:created_at), caption: ::Diagram.human_attribute_name(:created_at), sortable: "#{Diagram.table_name}.created_at")
    add_available_column EasyQueryDateColumn.new('updated_at', title: ::Diagram.human_attribute_name(:updated_at), caption: ::Diagram.human_attribute_name(:updated_at), sortable: "#{Diagram.table_name}.updated_at")

    @available_columns
  end

  def default_columns_names
    super.presence || [:title, :project, :author]
  end

  def default_list_columns
    super.presence || %w(title project author)
  end

  def add_additional_order_statement_joins(order_options)
    return if order_options.nil?

    joins = []

    if order_options.include?('project')
      joins << "LEFT OUTER JOIN #{Project.table_name} projects ON projects.id = #{self.entity_table_name}.project_id"
    end

    if order_options.include?('sort_author')
      joins << "LEFT OUTER JOIN #{User.table_name} sort_author ON sort_author.id = #{self.entity_table_name}.author_id"
    end

    joins
  end
end
