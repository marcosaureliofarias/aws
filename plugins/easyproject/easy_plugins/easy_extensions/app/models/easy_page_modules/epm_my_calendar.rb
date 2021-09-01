class EpmMyCalendar < EasyPageModule

  def category_name
    @category_name ||= 'calendars'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def editable?
    false
  end

  def get_show_data(settings, user, page_context = {})
    calendar        = Redmine::Helpers::Calendar.new((settings['start_date'] && settings['start_date'].to_date) || user.today, current_language, :week)
    calendar.events = Issue.visible(user).non_templates.open.preload([:status, :project, :tracker, :priority, :assigned_to]).
        where(["((#{Issue.table_name}.start_date BETWEEN ? AND ?) OR (#{Issue.table_name}.due_date BETWEEN ? AND ?)) AND #{Issue.table_name}.assigned_to_id = ?", calendar.startdt, calendar.enddt.end_of_day, calendar.startdt, calendar.enddt.end_of_day, user.id])
    calendar.sort_block { |is1, is2| is2.easy_start_date_time.to_i <=> is1.easy_start_date_time.to_i }

    return { :calendar => calendar }
  end

  def get_edit_data(settings, user, page_context = {})
    return get_show_data(settings, user, page_context)
  end

end
