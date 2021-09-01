class EpmTimelogQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'timelog'
  end

  def permissions
    @permissions ||= [:view_time_entries]
  end

  def query_class
    EasyTimeEntryQuery
  end

end
