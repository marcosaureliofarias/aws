class EpmEasyContactQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'contacts'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_easy_contacts, {})
  end

  def query_class
    EasyContactQuery
  end

end
