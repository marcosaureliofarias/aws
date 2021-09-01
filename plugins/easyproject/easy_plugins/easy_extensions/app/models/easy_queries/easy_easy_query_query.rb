class EasyEasyQueryQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'xproject_id', { type: :list_autocomplete, order: 1, source: 'visible_projects', source_root: 'projects' }
      add_principal_autocomplete_filter 'user_id', { order: 7, label: :field_author }
      add_available_filter 'name', { type: :string, order: 12, attr_reader: true }
      add_available_filter('role_id', {
          type:     :list_optional,
          order:    6,
          values:   proc { Role.sorted.map { |r| [r.name, r.id.to_s] } },
          label:    :label_easy_query_visible_for_roles
      })
    end
  end

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column 'name', sortable: "#{EasyQuery.table_name}.name"
      add_available_column 'user', caption: :field_author, groupable: "#{EasyQuery.table_name}.user_id", sortable: lambda { User.fields_for_order_statement('users') }, includes: [:user]
      add_available_column 'project', sortable: "#{Project.table_name}.name", groupable: "#{Project.table_name}.id", includes: [:project]
      add_available_column 'default_for_roles', caption: :label_easy_query_default_for_roles, sortable: "#{Role.table_name}.name", includes: [:default_for_roles]
      add_available_column 'visible_by_entities', caption: :label_easy_query_visible_by_entities, groupable: "#{EasyQuery.table_name}.visibility"
      add_available_column 'is_used_as_default_query', caption: :label_easy_query_is_used_as_default_query, preload: [:easy_default_query_mappings]
    end
  end

  def default_list_columns
    super.presence || %w[user name project default_for_roles roles]
  end


  def searchable_columns
    ["#{EasyQuery.table_name}.name"]
  end

  def entity_scope
    @entity_scope ||= EasyQuery
  end

  def tiles_support?
    false
  end

  def entity
    EasyQuery
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      roles_alias = "alias_#{Role.table_name}"
      if order_options.include?(roles_alias)
        joins << "LEFT OUTER JOIN easy_queries_roles ON easy_queries_roles.easy_query_id = #{self.entity.table_name}.id LEFT OUTER JOIN roles #{roles_alias} ON easy_queries_roles.role_id = #{roles_alias}.id"
      end
    end
    joins
  end

  def entity_easy_query_path(options = {})
    options        = options.dup
    options[:type] = self.type
    edit_easy_query_management_path(options)
  end

  def sql_for_role_id_field(field, operator, value)
    not_op = case operator
             when '!'
               operator = '='
             when '!*'
               operator = '*'
             end
    "#{not_op ? 'NOT ' : ''}EXISTS(SELECT 1 FROM easy_queries_roles WHERE (#{sql_for_field('role_id', operator, value, 'easy_queries_roles', 'role_id')}) AND easy_queries_roles.easy_query_id = easy_queries.id)"
  end

  def sql_for_xproject_id_field(field, operator, v)
    "(#{self.sql_for_field(field, operator, v, entity_table_name, 'project_id')})"
  end

  def self.report_support?
    false
  end

end
