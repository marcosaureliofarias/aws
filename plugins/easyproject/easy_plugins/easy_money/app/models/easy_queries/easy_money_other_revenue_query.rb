class EasyMoneyOtherRevenueQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_other_revenue
  end

  def entity
    EasyMoneyOtherRevenue
  end

  def self.chart_support?
    true
  end
  
  def entity_custom_field
    EasyMoneyOtherRevenueCustomField
  end

end