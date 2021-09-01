module EasyAttendancesHelper

  def easy_attandance_tabs
    tabs = [
        { name: 'calendar', partial: 'calendar', label: :label_calendar, redirect_link: true, url: easy_attendances_path(tab: 'calendar') },
        { name: 'list', partial: 'index', label: :label_list, redirect_link: true, url: easy_attendances_path(tab: 'list') },
        { name: 'report', partial: 'report', label: :label_report, redirect_link: true, url: report_easy_attendances_path(tab: 'report', report: { users: @user_ids }) },
        { name: 'detailed_report', partial: 'detailed_report', label: :label_detailed_report, redirect_link: true, url: detailed_report_easy_attendances_path(tab: 'detailed_report'), if: proc { User.current.allowed_to_globally?(:view_easy_attendance_other_users) } }
    ]
    tabs.delete_at(0) if in_mobile_view?

    return tabs
  end

  def easy_attendance_indicator(user)
    easy_attendance_indicator_css = 'user easy-attendance-indicator'

    if user.current_attendance && user.current_attendance.easy_attendance_activity.at_work?
      easy_attendance_indicator_css << ' online'
      easy_attendance_indicator = user.current_attendance.easy_attendance_activity.name
    else
      easy_attendance_indicator_css << ' offline'
      if (last_attendance_to_now = user.last_today_attendance_to_now) && !last_attendance_to_now.easy_attendance_activity.at_work?
        easy_attendance_indicator = last_attendance_to_now.easy_attendance_activity.name
      else
        easy_attendance_indicator = l(:label_general_offline)
      end
    end
    [easy_attendance_indicator, easy_attendance_indicator_css]
  end

  def easy_attendance_user_status_indicator(user)
    easy_attendance_indicator, easy_attendace_indicator_css = easy_attendance_indicator(user)

    hook_context = { :user => user, :easy_attendance_indicator => easy_attendance_indicator, :easy_attendace_indicator_css => easy_attendace_indicator_css }
    call_hook(:helper_application_link_to_user_in_easy_attendance, hook_context)

    easy_attendance_indicator = hook_context[:easy_attendance_indicator]

    easy_attendance_indicator = easy_attendance_indicator.join(' ').html_safe if easy_attendance_indicator.is_a?(Array)

    content_tag(:small, easy_attendance_indicator, :class => hook_context[:easy_attendace_indicator_css])
  end

  def easy_format_user_vacation_activity_days(activity, days)
    return '-' if activity.at_work?
    count = ('%.2f' % days).to_f
    content_tag(:span, l(:label_day, :count => ('%.2f' % days).to_f), class: ('red' if count < 0))
  end

  def approval_statuses
    l(:approval_statuses, scope: :easy_attendance).map { |key, value| [value, key] }
  end

  def formated_vacation_this_year(activity, user)
    easy_format_user_vacation_activity_days(activity, activity.user_vacation_limit_in_days(user).to_f)
  end

  def formated_remaing_vacation_this_year(activity, user)
    easy_format_user_vacation_activity_days(activity, activity.user_vacation_remaining_in_days(user, Date.current.year).to_f)
  end

  def easy_attendance_activities_for_select(easy_attendance)
    activities = EasyAttendanceActivity.user_activities.sorted.to_a
    activities.collect { |activity| [activity.name, activity.id] }
  end

  def easy_attendance_activities_for_autocomplete(easy_attendance)
    activities = EasyAttendanceActivity.user_activities.sorted.to_a
    if easy_attendance.persisted? && (current_activity = easy_attendance.activity)
      activities = activities.select { |activity| activity.at_work? == current_activity.at_work? }
    end
    activities.collect { |activity| { text: activity.name, value: activity.id } }.to_json
  end

  def total_hours_per_day(day_events)
    events = day_events.select { |x| x.is_a? EasyAttendances::EasyAttendanceCalendarDay }
    events.inject(0.0) { |sum, x| sum + x.events.values.flatten.inject(0.0) { |summ, y| summ + y.spent_time.to_f } }.to_f
  end

  def api_render_attendance(api, attendance, options = {})
    api.easy_attendance do
      api.id attendance.id
      api.user(id: attendance.user_id, name: attendance.user.name) unless attendance.user.nil?
      api.arrival attendance.arrival
      api.departure attendance.departure
      unless attendance.easy_attendance_activity.nil?
        api.easy_attendance_activity(id:   attendance.easy_attendance_activity_id,
                                     name: attendance.easy_attendance_activity.name)
      end
      api.locked attendance.locked
      api.arrival_user_ip attendance.arrival_user_ip
      api.departure_user_ip attendance.departure_user_ip
      api.range attendance.range
      api.created_at attendance.created_at
      api.updated_at attendance.updated_at
      api.description attendance.description
      api.need_approve attendance.need_approve?
      api.limit_exceeded !attendance.easy_attendance_vacation_limit_valid?
      api.hours(attendance.hours)
      api.easy_external_id(attendance.easy_external_id)
      if options[:with_factorized_attendances] && attendance.factorized_attendances.is_a?(Array)
        api.array :factorized_attendances do
          attendance.factorized_attendances.each do |factorized_attendance|
            api_render_attendance(api, factorized_attendance, options.except(:with_factorized_attendances))
          end
        end
      end
    end
  end
end
