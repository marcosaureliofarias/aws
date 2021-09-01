class EpmEasyMoneyOtherExpenseQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_other_expense]
  end

  def query_class
    EasyMoneyOtherExpenseQuery
  end

end