class EpmEasyCrmPieChartFromCustomField < EasyPageModule

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_easy_crms, {})
  end

  def get_show_data(settings, user, page_context = {})
    {}
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

end
