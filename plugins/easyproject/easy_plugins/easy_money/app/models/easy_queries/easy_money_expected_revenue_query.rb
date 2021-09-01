class EasyMoneyExpectedRevenueQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_expected_revenue
  end

  def entity
    EasyMoneyExpectedRevenue
  end

  def self.chart_support?
    true
  end

  def entity_custom_field
    EasyMoneyExpectedRevenueCustomField
  end

end