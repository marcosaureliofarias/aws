class EasyMoneyPeriodicalEntityQuery < EasyProjectQuery

  def self.permission_view_entities
    :view_easy_money
  end

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
    export                                         = ActiveSupport::OrderedHash.new
    export[:csv]                                   = {}
    export[:pdf]                                   = {}
    self.export_formats                            = export
    self.display_filter_sort_on_index              = false
    self.display_filter_group_by_on_edit           = true

    self.easy_query_entity_controller = 'easy_money_periodical_entities'
  end

  def project_module
    :easy_money
  end

  def initialize_available_filters
    super

    add_available_filter('main_project', { type: :list, order: 2, values: Proc.new { self.all_projects_parents_values }, group: l('label_filter_group_easy_project_query') })
  end

  def available_columns
    return @available_columns_added2 if @available_columns_added2
    @available_columns_added2 = super

    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_backlog_price_between, :title => 'Backlog', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_project_booking_price_between, :title => 'Booking', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_invoiced_price_between, :title => 'Invoiced', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_wpt_price_between, :title => 'Production Total', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_wpt_op_price_between, :title => 'PT - Internal Production', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_wpt_is_price_between, :title => 'PT - Intercompany subcontract', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_wpt_es_price_between, :title => 'PT - External subcontract', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_wip_price_between, :title => 'WIP', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_gm_price_between, :title => 'Gross Margin', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_gm_op_price_between, :title => 'GM - Internal Production', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_gm_is_price_between, :title => 'GM - Intercompany subcontract', :sumable => true, :sumable_sql => false)
    @available_columns_added2 << EasyQueryPeriodColumn.new(:empe_gm_es_price_between, :title => 'GM - External subcontract', :sumable => true, :sumable_sql => false)

    @available_columns_added2
  end

  def entity
    Project
  end

  def entity_scope
    @entity_scope ||= Project.visible.non_templates.has_module(:easy_money)
  end

end
