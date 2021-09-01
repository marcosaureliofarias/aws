class EasyResourceGroupQuery < Query

  self.queried_class = Group

  self.available_columns = [
    QueryColumn.new(:lastname, sortable: "#{Group.table_name}.lastname", groupable: true),
    QueryColumn.new(:created_on, sortable: "#{Group.table_name}.created_on"),
    QueryColumn.new(:updated_on, sortable: "#{Group.table_name}.updated_on"),
  ]

  def default_columns_names
    @default_columns_names ||= [:firstname, :lastname, :mail]
  end

  def initialize_available_filters
    add_available_filter 'lastname', type: :text
    add_available_filter 'created_on', type: :date_past
    add_available_filter 'updated_on', type: :date_past
  end

  def groups(options = {})
    order_option = options[:order] || Group.fields_for_order_statement.join(', ')

    scope = Group.givable
    scope.where(statement).
          includes((options[:include] || []).uniq).
          where(options[:conditions]).
          order(order_option).
          joins(joins_for_order_statement(order_option)).
          limit(options[:limit]).
          offset(options[:offset])
  end

  private

  # def joins_for_statement
  #   "INNER JOIN #{Project.table_name} ON #{Member.table_name}.project_id = #{Project.table_name}.id" if project
  # end

  # def sql_for_mail_field(field, operator, value)
  #   operator = operator == "=" ? operator : "!="
  #   value = value.first if value.is_a?(Array)

  #   "#{EmailAddress.table_name}.address #{operator} '#{value}'"
  # end

  # def sql_for_admin_field(field, operator, value)
  #   operator = operator == "=" ? operator : "!="

  #   "#{queried_table_name}.#{field} #{operator} #{!!value}"
  # end

end
