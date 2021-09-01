class EpmVersionQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'projects'
  end

  def permissions
    @permissions ||= [:view_project]
  end

  def query_class
    EasyVersionQuery
  end

end