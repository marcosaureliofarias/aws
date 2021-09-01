class EasyResourceUserQuery < Query

  # COLUMNS_PREFIX = "user_query_"

  self.queried_class = User

  self.available_columns = [
    QueryColumn.new(:login, :sortable => "#{User.table_name}.login"),
    QueryColumn.new(:firstname, :sortable => "#{User.table_name}.firstname", :groupable => true),
    QueryColumn.new(:lastname, :sortable => "#{User.table_name}.lastname", :groupable => true),
    QueryColumn.new(:mail, :sortable => "#{EmailAddress.table_name}.address"),
    QueryColumn.new(:admin, :sortable => "#{User.table_name}.admin", :groupable => true),
    QueryColumn.new(:created_on, :sortable => "#{User.table_name}.created_on"),
    QueryColumn.new(:status, :sortable => "#{User.table_name}.status", :groupable => true)
  ]

  def default_columns_names
    @default_columns_names ||= [:firstname, :lastname, :mail]
  end

  def initialize_available_filters
    add_available_filter "login", :type => :text
    add_available_filter "firstname", :type => :text
    add_available_filter "lastname", :type => :text
    add_available_filter "mail", :type => :text
    add_available_filter "admin",
      :type => :list,
      :values => [[l(:general_text_yes), true], [l(:general_text_no), false]]
    add_available_filter "created_on", :type => :date_past
    add_available_filter "status",
      :type => :list,
      :values => [
        [l(:status_active), User::STATUS_ACTIVE.to_s],
        [l(:status_registered), User::STATUS_REGISTERED],
        [l(:status_locked), User::STATUS_LOCKED]
      ]
  end

  def users(options = {})
    order_option = options[:order] || User.fields_for_order_statement.join(', ')

    if project
      scope = project.assignable_users.joins(joins_for_statement)
    else
      scope = User.visible
    end

    scope.where(User.table_name => { :status => User::STATUS_ACTIVE }).
      joins(joins_for_filters).
      where(statement).
      includes((options[:include] || []).uniq).
      preload(options[:preload]).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option)).
      limit(options[:limit]).
      offset(options[:offset])
  end

  def sql_for_mail_field(field, operator, value)
    sql_for_field(field, operator, value, EmailAddress.table_name, 'address')
  end

  def sql_for_admin_field(field, operator, value)
    value = value.first.to_s.to_boolean ? self.class.connection.quoted_true : self.class.connection.quoted_false
    sql_for_field(field, operator, [value], queried_table_name, field)
  end

  private

  def joins_for_filters
    joins = []

    if (filters || []).include?('mail')
      joins << "LEFT OUTER JOIN #{EmailAddress.table_name} ON #{User.table_name}.id = #{EmailAddress.table_name}.user_id"
    end
    joins
  end

  def joins_for_statement
    "INNER JOIN #{Project.table_name} ON #{Member.table_name}.project_id = #{Project.table_name}.id" if project
  end

end
