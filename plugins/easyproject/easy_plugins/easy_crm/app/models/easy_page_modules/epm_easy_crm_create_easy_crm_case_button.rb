class EpmEasyCrmCreateEasyCrmCaseButton < EasyPageModule

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:edit_easy_crm_cases, {}) || user.allowed_to_globally?(:edit_own_easy_crm_cases, {})
  end

  def get_show_data(settings, user, page_context = {})
    {}
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

end
