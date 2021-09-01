class EpmEasyHelpdeskProjectQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'easy_helpdesk'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:manage_easy_helpdesk, {})
  end

  def query_class
    EasyHelpdeskProjectQuery
  end

end
