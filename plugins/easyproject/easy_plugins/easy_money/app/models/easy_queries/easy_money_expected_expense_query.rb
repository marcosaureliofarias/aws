class EasyMoneyExpectedExpenseQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_expected_expense
  end

  def entity
    EasyMoneyExpectedExpense
  end

  def self.chart_support?
    true
  end

  def entity_custom_field
    EasyMoneyExpectedExpenseCustomField
  end

end