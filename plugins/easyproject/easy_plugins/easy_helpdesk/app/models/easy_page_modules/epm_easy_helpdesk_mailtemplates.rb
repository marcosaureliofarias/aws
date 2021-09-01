class EpmEasyHelpdeskMailtemplates < EasyPageModule

  def category_name
    @category_name ||= 'easy_helpdesk'
  end

  def permissions
    @permissions ||= [:manage_easy_helpdesk]
  end

  def get_data(settings, user, page_context = {})
    {
      :easy_helpdesk_mail_templates => EasyHelpdeskMailTemplate.includes([:issue_status, :mailboxes]).references(:mailboxes).order("#{EasyRakeTaskEasyHelpdeskReceiveMail.table_name}.id").limit(10).to_a,
      :easy_helpdesk_mail_templates_count => EasyHelpdeskMailTemplate.all.count
    }
  end

  def get_show_data(settings, user, page_context = {})
    get_data(settings, user, page_context = {})
  end

  def get_edit_data(settings, user, page_context = {})
    get_data(settings, user, page_context = {})
  end

end
