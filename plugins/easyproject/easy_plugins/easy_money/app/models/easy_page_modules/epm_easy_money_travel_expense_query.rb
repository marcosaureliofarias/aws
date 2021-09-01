class EpmEasyMoneyTravelExpenseQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_travel_expense]
  end

  def query_class
    EasyMoneyTravelExpenseQuery
  end

end