class EpmEasyHelpdeskCreateMailboxButton < EasyPageModule

  def category_name
    @category_name ||= 'easy_helpdesk'
  end

  def permissions
    @permissions ||= [:manage_easy_helpdesk]
  end

  def get_show_data(settings, user, page_context = {})
    {}
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

end
