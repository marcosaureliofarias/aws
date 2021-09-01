class EpmEasyCrmUserTarget < EasyPageModule

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_easy_crms, {})
  end

  def query_class
    EasyUserTargetQuery
  end

  def get_show_data(settings, user, page_context = {})
   {}
  end

  def get_edit_data(settings, user, page_context = {})
    users = User.where(has_target: true).sorted

    {users: users }
  end

end