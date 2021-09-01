class EasyKnowledgeStoryQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_knowledge
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def query_after_initialize
    super
    self.export_formats[:atom] = { :url => { :key => User.current.rss_key } }
  end

  def entity_scope
    @entity_scope ||= entity.visible
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', { type: :text, order: 1 }
      add_principal_autocomplete_filter 'author_id', { order: 2, source_options: { internal_non_system: true } }
      add_available_filter 'created_on', { type: :date_period, order: 3 }
      add_available_filter 'updated_on', { type: :date_period, order: 4 }
      add_available_filter 'tags', { type: :list_autocomplete, order: 5, label: :label_easy_tags, source: 'tags', source_root: '' }
      add_available_filter 'recomended_to', { type: :list, order: 6, values: recomended_to_values }
      add_available_filter 'projects', { type: :list, order: 7, values: proc { all_projects_values } }
      add_available_filter 'issues', { type: :list, order: 8, values: issue_values }
      add_available_filter 'favorited', { type: :boolean, order: 9 }
      add_available_filter 'category', { type: :list_optional, order: 10, values: proc { EasyKnowledgeCategory.visible.select(:name, :id).map { |c| [c.name, c.id.to_s] } } }
    end

    add_custom_fields_filters(EasyKnowledgeStoryCustomField)
  end

  def available_columns
    unless @available_columns_added
      group              = l('label_easy_knowledge')
      @available_columns = [
          EasyQueryColumn.new(:name, :sortable => "#{EasyKnowledgeStory.table_name}.name", :groupable => true, :group => group),
          EasyQueryColumn.new(:author, :groupable => "#{EasyKnowledgeStory.table_name}.author_id", :sortable => lambda { User.fields_for_order_statement('authors') }, :preload => [:author => :easy_avatar], :group => group),
          EasyQueryColumn.new(:storyviews, :sortable => "#{EasyKnowledgeStory.table_name}.storyviews", :groupable => true, :group => group),
          EasyQueryColumn.new(:categories_count, :sortable => "(SELECT COUNT(#{EasyKnowledgeStoryCategory.table_name}.category_id) FROM #{EasyKnowledgeStoryCategory.table_name} WHERE #{EasyKnowledgeStoryCategory.table_name}.story_id = #{EasyKnowledgeStory.table_name}.id)", :groupable => true, :group => group),
          EasyQueryColumn.new(:updated_on, :sortable => "#{EasyKnowledgeStory.table_name}.updated_on", :groupable => true, :group => group),
          EasyQueryColumn.new(:created_on, :sortable => "#{EasyKnowledgeStory.table_name}.created_on", :groupable => true, :group => group),
          EasyQueryColumn.new(:tags, :preload => [:tags], :caption => :label_easy_tags, :group => group),
          EasyQueryColumn.new(:recomended_to, :group => group),
          EasyQueryColumn.new(:projects, :includes => { :easy_knowledge_assigned_stories => :project }, :group => group),
          EasyQueryColumn.new(:issues, :includes => { :easy_knowledge_assigned_stories => :issue }, :group => group),
          EasyQueryColumn.new(:categories, :preload => [:easy_knowledge_categories], :caption => :label_easy_knowledge_category, :group => group)
      ]
      group              = l('label_user_plural')
      @available_columns << EasyQueryColumn.new(:author, :sortable => "#{EasyKnowledgeStory.table_name}.name", :groupable => true, :includes => [:author], :group => group)

      @available_columns.concat(EasyKnowledgeStory.available_custom_fields.collect { |cf| EasyQueryCustomFieldColumn.new(cf) })
      @available_columns_added = true
    end
    @available_columns
  end

  def searchable_columns
    [
        "#{EasyKnowledgeStory.table_name}.description", "#{EasyKnowledgeStory.table_name}.name", "#{ActsAsTaggableOn::Tag.table_name}.name"
    ]
  end

  def columns_with_me
    super + ['recomended_to']
  end

  def default_list_columns
    super.presence || ['name', 'author', 'storyviews', 'updated_on', 'tags']
  end

  def default_find_include
    [:tags]
  end

  def default_find_preload
    [:current_user_read_records]
  end

  def all_projects(with_enabled_module = true)
    projects = Project.arel_table
    assigned = EasyKnowledgeAssignedStory.arel_table
    super.where(EasyKnowledgeAssignedStory.where(assigned[:entity_type].eq('Project').and(projects[:id].eq(assigned[:entity_id]))).arel.exists)
  end

  def issue_values
    Proc.new do
      issues   = Issue.arel_table
      assigned = EasyKnowledgeAssignedStory.arel_table
      Issue.visible.non_templates.where(EasyKnowledgeAssignedStory.where(assigned[:entity_type].eq('Issue').and(issues[:id].eq(assigned[:entity_id]))).arel.exists).all.collect { |issue| [issue.subject, issue.id.to_s] }
    end
  end

  def recomended_to_values
    Proc.new do
      users_values = []
      users        = User.arel_table
      assigned     = EasyKnowledgeAssignedStory.arel_table
      all_values   = User.active.non_system_flag.easy_type_internal.where(EasyKnowledgeAssignedStory.where(assigned[:entity_type].eq('Principal').and(users[:id].eq(assigned[:entity_id]))).arel.exists)

      users_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
      all_values.each { |u| users_values << [u.to_s, u.id.to_s] }
      users_values
    end
  end

  def entity
    EasyKnowledgeStory
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{EasyKnowledgeStory.table_name}.author_id"
      end
    end
    joins
  end

  def search_freetext_with_categories(tokens, options)
    @search_string ||= tokens.is_a?(String) ? tokens : ''

    options[:joins] ||= []
    options[:joins] << "LEFT OUTER JOIN #{EasyKnowledgeStoryCategory.table_name} ON #{EasyKnowledgeStoryCategory.table_name}.story_id = #{EasyKnowledgeStory.table_name}.id" if User.current.admin?
    options[:joins] << "LEFT OUTER JOIN #{EasyKnowledgeCategory.table_name} c ON c.id = #{EasyKnowledgeStoryCategory.table_name}.category_id" # AND c.entity_type != 'Principal'"

    search_freetext(tokens, options)
  end

  def search_freetext_where_conditions(sql, tokens, token_clauses)
    if @search_string.present?
      lft, rgt = EasyKnowledgeCategory.where("name LIKE ? ", "%#{@search_string}%").pluck(:lft, :rgt).first

      if lft && rgt
        sql ||= ''
        sql << ' OR ' if sql.present?
        sql << "(c.lft >= #{lft} AND c.rgt <= #{rgt})"
      end
    end

    super(sql, tokens, token_clauses)
  end

  def sql_for_category_field(field, operator, value)
    tbl    = EasyKnowledgeStoryCategory.table_name
    not_op = operator.start_with?('!') ? 'NOT ' : ''
    case operator
    when '!'
      operator = '='
    when '!*'
      operator = '*'
    end
    sql = sql_for_field('category_id', operator, value, tbl, 'category_id')
    "#{not_op}EXISTS (SELECT 1 FROM #{tbl} WHERE #{tbl}.story_id = #{entity_table_name}.id AND #{sql})"
  end

  protected

  def get_custom_sql_for_field(field, operator, value)
    return case field
           when 'recomended_to'
             sql_for_assigned_field(field, operator, value, 'Principal')
           when 'projects'
             sql_for_assigned_field(field, operator, value, 'Project')
           when 'issues'
             sql_for_assigned_field(field, operator, value, 'Issue')
           end
  end

  def sql_for_assigned_field(field, operator, value, entity_type)
    db_table = EasyKnowledgeAssignedStory.table_name
    db_field = 'entity_id'
    sql      = "#{EasyKnowledgeStory.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.story_id FROM #{db_table} WHERE #{db_table}.entity_type='#{entity_type}' AND "
    sql << sql_for_field(field, '=', value, db_table, db_field) + ')'
  end
end
