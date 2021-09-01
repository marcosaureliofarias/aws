class EpmEasyCalendar < EasyPageModule

  def category_name
    @category_name ||= 'calendars'
  end

  def permissions
    @permissions ||= [:view_easy_calendar]
  end

  # def get_show_data(settings, user, page_context = {})
    # calendar.events = Issue.visible(user).non_templates.open.includes([:status, :project, :tracker, :priority, :assigned_to]).where(["((#{Issue.table_name}.start_date BETWEEN ? AND ?) OR (#{Issue.table_name}.due_date BETWEEN ? AND ?)) AND #{Issue.table_name}.assigned_to_id = ?", calendar.startdt, calendar.enddt, calendar.startdt, calendar.enddt, user.id])
    # calendar.sort_block {|is1,is2| is2.easy_start_date_time.to_i <=> is1.easy_start_date_time.to_i}
    # return {:calendar => nil}
  # end

  def get_edit_data(settings, user, page_context = {})
    return get_show_data(settings, user, page_context)
  end

  def get_show_data(settings, user, page_context = {})
    p = page_context[:params]
    users = User.where(:id => p['user_ids']).to_a if p && p['user_ids'].present?
    users ||= (User.where(:id => settings['user_ids']).to_a if settings['user_ids'].present?)
    users ||= []

    return {:users => users}
  end

  def default_settings
    @default_settings ||= {
      :display_from => '09:00',
      :display_to => '20:00',
      :enabled_calendars => [],
      :user_ids => [],
      :default_view => 'month'
    }.with_indifferent_access
  end

end
