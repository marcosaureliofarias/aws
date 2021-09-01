class EpmTimelogCalendar < EasyPageModule

  def category_name
    @category_name ||= 'timelog'
  end

  def get_show_data(settings, user, page_context = {})
    start_date = settings['start_date'].blank? ? user.today : settings['start_date'].to_date
    calendar   = EasyExtensions::Timelog::Calendar.new(start_date, user.language, (settings['period'].blank? ? :month : settings['period'].to_sym))

    scope              = TimeEntry.non_templates.visible_with_archived.where(user_id: user.id).where("spent_on BETWEEN ? AND ?", calendar.startdt, calendar.enddt.end_of_day)
    spent_time_per_day = scope.group(:spent_on).sum(:hours)

    { calendar: calendar, spent_time_per_day: spent_time_per_day, perm_log_time: user.allowed_to?(:log_time, nil, global: true), perm_view_time_entries: user.allowed_to?(:view_time_entries, nil, global: true) }
  end

end
