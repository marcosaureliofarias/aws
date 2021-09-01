class EpmEasyMoneyProjectCacheQuery < EpmEasyMoneyBaseQuery

  def permissions
    @permissions ||= [:view_easy_money]
  end

  def query_class
    EasyMoneyProjectCacheQuery
  end

end