class EpmEasyMoneyExpectedRevenueQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_expected_revenue]
  end

  def query_class
    EasyMoneyExpectedRevenueQuery
  end

end