class EpmEasyEntityActivityCrmCaseQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_easy_crms, {})
  end

  def query_class
    EasyEntityActivityCrmCaseQuery
  end

end
