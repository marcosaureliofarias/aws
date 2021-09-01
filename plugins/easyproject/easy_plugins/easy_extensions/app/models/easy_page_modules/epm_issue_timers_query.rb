class EpmIssueTimersQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'timelog'
  end

  def permissions
    @permissions ||= [:view_issue_timers_of_others]
  end

  def query_class
    EasyIssueTimerQuery
  end

end
