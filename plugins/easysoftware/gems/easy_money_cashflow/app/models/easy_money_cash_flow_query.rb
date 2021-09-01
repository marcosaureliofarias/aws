class EasyMoneyCashFlowQuery < EasyProjectQuery

  def self.permission_view_entities
    :view_easy_money
  end

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
    export = ActiveSupport::OrderedHash.new
    export[:xlsx] = {}
    self.export_formats = export
    self.easy_query_entity_controller = 'easy_money_cash_flow'
    self.easy_query_entity_action = 'index'
  end

  def available_columns
    super
    unless @available_cashflow_columns_added
      group = l('easy_query.name.easy_money_cash_flow_query')
      if User.current.allowed_to_globally?(:easy_money_cash_flow_history, {})
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_other_revenues_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_other_revenues_price2, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_other_expenses_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_other_expenses_price2, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_time_entry_expenses_price, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_travel_expenses_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_travel_costs_price1, sumable: true, sumable_sql: false, group: group, query: self)

        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_history_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_history_price2, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_total_costs_price1, sumable: true, sumable_sql: false, group: group, query: self)
      end
      if User.current.allowed_to_globally?(:easy_money_cash_flow_prediction, {})
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_expected_revenues_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_expected_revenues_price2, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_expected_expenses_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_expected_expenses_price2, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_expected_payroll_expenses_price, sumable: true, sumable_sql: false, group: group, query: self)

        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_prediction_price1, sumable: true, sumable_sql: false, group: group, query: self)
        @available_columns << EasyQueryPeriodColumn.new(:empe_cashflow_prediction_price2, sumable: true, sumable_sql: false, group: group, query: self)
      end
      @available_cashflow_columns_added = true
    end
    @available_columns
  end

  def default_list_columns
    super.presence || %w[name empe_cashflow_history_price1 empe_cashflow_history_price2 empe_cashflow_prediction_price1 empe_cashflow_prediction_price2]
  end

  def project_module
    :easy_money
  end

  def entity_scope
    @entity_scope ||= Project.visible.non_templates.has_module(:easy_money)
  end

  def entity_easy_query_path(options)
    easy_money_cash_flow_path(options)
  end

  def summarize_column(column, entities, group = nil, options = {})
    if entities && !column.sumable_sql
      delete_children(entities).sum { |i| column.value(i) || 0.0 }
    else
      super
    end
  end

  def self.chart_support?
    false
  end

  def currency_columns?
    true
  end

  private

  def delete_children(projects)
    result = []
    result_range = []
    stash = projects.sort_by { |x| -x.rgt + x.lft }
    stash.each do |x|
      cover = ((x.lft..x.rgt).to_a - result_range)
      if cover.any?
        result << x
        if x.easy_money_settings.include_childs?
          result_range.concat(cover)
        end
      end
    end
    result
  end
end
