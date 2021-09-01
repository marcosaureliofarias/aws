class EasyMoneyOtherExpenseQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_other_expense
  end

  def entity
    EasyMoneyOtherExpense
  end

  def self.chart_support?
    true
  end

  def entity_custom_field
    EasyMoneyOtherExpenseCustomField
  end
  
end