class EpmEasyMoneyExpectedExpenseQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_expected_expense]
  end

  def query_class
    EasyMoneyExpectedExpenseQuery
  end

end
