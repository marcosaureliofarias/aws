class EpmEasyMoneyOtherRevenueQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_other_revenue]
  end

  def query_class
    EasyMoneyOtherRevenueQuery
  end

end