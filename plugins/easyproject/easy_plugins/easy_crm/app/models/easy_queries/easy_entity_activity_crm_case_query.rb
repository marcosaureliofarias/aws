class EasyEntityActivityCrmCaseQuery < EasyEntityActivityQuery

  def entity_scope
    EasyEntityActivity.where(entity_type: ['EasyCrmCase', 'EasyContact'])
  end

  def entity_easy_query_path(options = {})
    sales_activities_path(options)
  end

  def initialize_available_filters
    super
    add_associations_filters EasyCrmCaseQuery, skip_associated_cf: true
    add_associations_filters EasyContactQuery
  end

  def initialize_available_columns
    super
    add_associated_columns EasyCrmCaseQuery
    add_associated_columns EasyContactQuery
  end

  def self.chart_support?
    true
  end

  def get_custom_sql_for_field(field, operator, value)
    case field.to_s
    when /sales_activity_\d+_not_in$/
      sql_for_sales_activity(field, operator, value)
    else
      super(field, operator, value)
    end
  end

  def sql_for_sales_activity(field, operator, value)
    if field.match /(\d+)/
      category_id = $1
      db_table = 'eea'
      db_field = 'start_time'
      time_statement = sql_for_field(field, operator, value, db_table, db_field)
      sql = "#{EasyCrmCase.table_name}.id NOT IN (SELECT eea.entity_id FROM #{EasyEntityActivity.table_name} eea WHERE eea.entity_type = 'EasyCrmCase' #{time_statement.present? ? 'AND ' + time_statement : ''} AND eea.category_id = #{category_id})"
    end
    sql || '(1=0)'
  end

end
