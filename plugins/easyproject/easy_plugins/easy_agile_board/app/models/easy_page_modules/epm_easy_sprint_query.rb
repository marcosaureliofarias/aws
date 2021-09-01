class EpmEasySprintQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'easy_agile_board'
  end

  def permissions
    @permissions ||= [:view_easy_scrum_board]
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_global_easy_sprints, {})
  end

  def query_class
    EasySprintQuery
  end

end
