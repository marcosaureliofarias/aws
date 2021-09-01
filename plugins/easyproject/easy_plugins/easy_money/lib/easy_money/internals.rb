module EasyMoney
  def self.easy_money_base_entities
    [ EasyMoneyOtherRevenue, EasyMoneyExpectedRevenue,
      EasyMoneyOtherExpense, EasyMoneyExpectedExpense,
      EasyMoneyExpectedPayrollExpense, EasyMoneyTravelCost,
      EasyMoneyTravelExpense
    ].freeze
  end
end