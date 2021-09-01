module EasyMoneyEntityBudgetQueryConcern
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def easy_money_entities
      %i(
        planned_incomes         actual_incomes
        planned_expenses        actual_expenses
        planned_total_expenses  actual_total_expenses
        planned_profit          actual_profit
      )
    end

    # planned_total_expenses  actual_total_expenses should be also with custom sql.
    def easy_money_entities_with_sumable_sql
      %i(
        planned_incomes         actual_incomes
        planned_expenses        actual_expenses
      )
    end

    def none_sumable_easy_money_entities
      %i(planned_profit actual_profit)
    end

    def easy_money_personal_costs
      %i(planned_personal_costs actual_personal_costs)
    end

    def easy_money_margin_columns
      %i(profit_margin net_margin)
    end

    def easy_money_columns
      easy_money_entities.reduce([]) do |array, entity|
        array.concat ["#{entity}_with_vat".to_sym, "#{entity}_without_vat".to_sym]
      end + easy_money_personal_costs
    end
  end

  def decorator_class
    EasyMoney::IssueBudgetQueryDecorator
  end

  def entities(options = {})
    super(options).map do |entity|
      decorator_class.new(entity, self)
    end
  end

  def entities_for_group(group, options = {})
    super(group, options).map do |entity|
      decorator_class.new(entity, self)
    end
  end

  def available_filters
    super

    unless @available_easy_money_entities_budget_filters_added
      status_time_group = l('label_filter_group_status_time')
      status_count_group = l('label_filter_group_status_count')

      @available_filters.delete_if do |field, options|
        options[:group] == status_time_group || options[:group] == status_count_group
      end

      @available_easy_money_entities_budget_filters_added = true
    end

    @available_filters
  end

  def available_columns
    super

    return @available_columns if @available_easy_money_entities_budget_columns_added

    self.class.easy_money_entities.each do |easy_money_entity|
      
      @available_columns << create_easy_money_entity_column(easy_money_entity, vat: true, title: easy_money_column_caption(easy_money_entity, true))

      if require_vat?
        @available_columns << create_easy_money_entity_column(easy_money_entity, vat: false, title: easy_money_column_caption(easy_money_entity, false))
      end
    end

    self.class.easy_money_personal_costs.each do |easy_money_entity|
      @available_columns << create_easy_money_entity_column(easy_money_entity, title: l(easy_money_entity, scope: 'easy_query.columns.easy_money_query'))
    end

    self.class.easy_money_margin_columns.each do |easy_money_entity|
      @available_columns << create_easy_money_entity_column(easy_money_entity, sumable: nil, sumable_sql: nil, title: l(easy_money_entity, scope: 'easy_query.columns.easy_money_query'))
    end

    status_time_group = l('label_filter_group_status_time')
    status_count_group = l('label_filter_group_status_count')

    @available_columns.delete_if do |easy_query_column|
      easy_query_column.group == status_time_group || easy_query_column.group == status_count_group
    end

    @available_easy_money_entities_budget_columns_added = true

    @available_columns
  end

  def default_column_options
    { group: default_column_group, query: self }
  end

  def default_column_group
    l(:label_filter_group_easy_money_budget_entities)
  end

  def easy_money_column_options(base, options = {})
    {}.tap do |h|
      h.merge!(default_column_options)
      h.merge!(sumable_column_options(base, options)) if self.class.easy_money_entities_with_sumable_sql.include?(base)
      h.merge!(sumable: nil, sumable_sql: nil) if self.class.none_sumable_easy_money_entities.include?(base)
    end
  end

  def sumable_column_options(base, options = {})
    vat = options[:vat]
    { sumable: :top, sumable_sql: easy_money_column_sumable_sql(base, vat) }
  end 

  def create_easy_money_entity_column(base, options = {})
    column_name = base if options[:vat].nil?
    column_name ||= options[:vat] ? "#{base}_with_vat" : "#{base}_without_vat"
    column_options = easy_money_column_options(base, options).merge(options)

    EasyQueryColumn.new(column_name, column_options)
  end

  def easy_money_column_caption(base, vat = true)
    title = l(base, scope: 'easy_query.columns.easy_money_query')

    if vat && require_vat?
      title << ' ' << l('easy_query.suffixes.easy_money_query.with_vat')
    elsif !vat
      title << ' ' << l('easy_query.suffixes.easy_money_query.without_vat')
    end

    title
  end

  def easy_money_column_sumable_sql(base, vat = true)
    price_type = vat ? :price1 : :price2
    case base
    when :planned_incomes
      scope = get_easy_money_entity_scope_for(EasyMoneyExpectedRevenue, :easy_money_show_expected_revenue, price_type)
      return "COALESCE((#{scope}), 0)"
    when :actual_incomes
      scope = get_easy_money_entity_scope_for(EasyMoneyOtherRevenue, :easy_money_show_other_revenue, price_type)
      return "COALESCE((#{scope}), 0)"
    when :planned_expenses
      scope = get_easy_money_entity_scope_for(EasyMoneyExpectedExpense, :easy_money_show_expected_expense, price_type)
      return "COALESCE((#{scope}), 0)"
    when :actual_expenses
      scope = get_easy_money_entity_scope_for(EasyMoneyOtherExpense, :easy_money_show_other_expense, price_type) 
      return "COALESCE((#{scope}), 0)"     
    end
  end

  def get_easy_money_entity_scope_for(entity_class, permission, price_type)
    price_column = get_price_column(price_type)
    scope_string = %{
      SELECT SUM(#{entity_class.table_name}.#{price_column})
      FROM #{entity_class.table_name}
      WHERE #{entity_class.table_name}.entity_type = '#{self.entity}' AND #{entity_class.table_name}.entity_id = #{self.entity.table_name}.id
    }

    scope_string.squish
  end

  def require_vat?
    EasyMoneySettings.find_settings_by_name('price_visibility', project) == 'all'
  end

  def get_price_column(original_column)
    if easy_currency_code && EasyCurrency[easy_currency_code]
      "#{original_column}_#{easy_currency_code}"
    else
      original_column
    end
  end

  def currency_columns?
    true
  end

  def easy_currency_code
    super.presence || project&.easy_currency_code
  end

  def easy_money_settings
    project&.easy_money_settings
  end

  def default_group_label
    raise NotImplementedError
  end

end
