class EpmEasyHelpdeskMailboxes < EasyPageModule

  def category_name
    @category_name ||= 'easy_helpdesk'
  end

  def permissions
    @permissions ||= [:manage_easy_helpdesk]
  end

  def last_infos
    last_info_ids = EasyRakeTaskInfo.where(easy_rake_task_id: EasyRakeTaskEasyHelpdeskReceiveMail.all).group(:easy_rake_task_id).maximum(:id).values

    EasyRakeTaskInfo.where(id: last_info_ids).inject({}){|var, info| var[info.easy_rake_task_id] = info; var }
  end

  def get_data(settings, user, page_context = {})
    {
      tasks: EasyRakeTaskEasyHelpdeskReceiveMail.limit(10).all,
      tasks_count: EasyRakeTaskEasyHelpdeskReceiveMail.count,
      last_infos: last_infos
    }
  end

  def get_show_data(settings, user, page_context = {})
    get_data(settings, user, page_context = {})
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

end
