class EpmMyContactsButton < EasyPageModule

  def category_name
    @category_name ||= 'contacts'
  end

  def permissions
    @permissions ||= [:view_easy_contacts]
  end

  def get_show_data(settings, user, page_context = {})
    {}
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

end
