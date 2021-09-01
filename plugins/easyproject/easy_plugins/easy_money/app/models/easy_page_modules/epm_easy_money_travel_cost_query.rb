class EpmEasyMoneyTravelCostQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:easy_money_show_travel_cost]
  end

  def query_class
    EasyMoneyTravelCostQuery
  end

end