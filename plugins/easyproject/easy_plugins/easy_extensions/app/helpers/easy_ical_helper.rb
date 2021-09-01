require 'icalendar'
require 'open-uri'
require 'timeout'

module EasyIcalHelper

  def issues_to_ical(issues, options = {})
    icalendar = Icalendar::Calendar.new
    icalendar.append_custom_property('METHOD', 'PUBLISH')
    icalendar.append_custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'TRUE')
    issues.each { |issue| icalendar = issue_to_ical_obj(icalendar, issue) }
    icalendar.to_ical
  end

  def issue_to_ical(issue, options = {})
    icalendar = Icalendar::Calendar.new
    if options[:method] == 'request'
      icalendar.append_custom_property('METHOD', 'REQUEST')
    else
      icalendar.append_custom_property('METHOD', 'PUBLISH')
    end
    icalendar.append_custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'FALSE')
    icalendar = issue_to_ical_obj(icalendar, issue)
    icalendar.to_ical
  end

  def issue_to_ical_obj(icalendar, issue)
    cv_start, cv_end, cv_location = get_issue_ical_start_date(issue), get_issue_ical_end_date(issue), get_issue_ical_location(issue)

    icalendar.event do |e|
      if cv_start.present?
        e.dtstart = Icalendar::Values::DateOrDateTime.new(cv_start)
      end
      if cv_end.present?
        e.dtend = Icalendar::Values::DateOrDateTime.new(cv_end)
      end
      e.summary       = issue.subject
      e.description   = Sanitize.clean(issue.description.to_s, :output => :html).strip
      e.created       = issue.created_on
      e.last_modified = issue.updated_on
      e.uid           = issue.id.to_s + '@' + Setting.host_name
      e.url           = issue_url(issue)
      e.sequence      = 0
      # e.transparency = 'OPAQUE'
      e.ip_class = 'PUBLIC'
      e.location = cv_location unless cv_location.blank?
      e.priority = '5'
      e.status   = 'CONFIRMED'

      e.append_custom_property('X-MICROSOFT-CDO-BUSYSTATUS', 'BUSY')
      e.append_custom_property('X-MICROSOFT-CDO-IMPORTANCE', '1')
      e.append_custom_property('X-MICROSOFT-DISALLOW-COUNTER', 'FALSE')
      e.append_custom_property('X-MS-OLK-AUTOFILLLOCATION', 'FALSE')
      e.append_custom_property('X-MS-OLK-AUTOSTARTCHECK', 'FALSE')
      e.append_custom_property('X-MS-OLK-CONFTYPE', '0')

      e.organizer = ("mailto:#{issue.author.mail}") if issue.author && issue.author.mail.present?

      if issue.assigned_to
        attendee = Icalendar::Values::CalAddress.new("MAILTO:#{issue.assigned_to.mail}", { 'CN' => issue.assigned_to.to_s })
        e.append_attendee(attendee)
      end

      unless issue.watcher_users.blank?
        issue.watcher_users.each do |w|
          next if w.mail.blank?
          attendee = Icalendar::Values::CalAddress.new("MAILTO:#{w.mail}", { 'CN' => w.to_s })
          e.append_attendee(attendee)
        end
      end
    end
    icalendar
  end

  def get_issue_ical_start_date(issue)
    datetimes         = issue.available_custom_fields.select { |cf| cf.field_format == 'datetime' }
    cf_start          = datetimes && datetimes.first
    cv_start          = issue.custom_value_for(cf_start) if cf_start

    return_start_date = cv_start.cast_value if cv_start
    return_start_date ||= User.current.user_time_in_zone(issue.easy_start_date_time) if issue.respond_to?(:easy_start_date_time) && !issue.easy_start_date_time.nil?
    return_start_date ||= issue.start_date
    return_start_date ||= issue.due_date
    return return_start_date
  end

  def get_issue_ical_end_date(issue)
    datetimes       = issue.available_custom_fields.select { |cf| cf.field_format == 'datetime' }
    cf_end          = datetimes && datetimes.second
    cv_end          = issue.custom_value_for(cf_end) if cf_end

    return_end_date = cv_end.cast_value if cv_end
    return_end_date ||= User.current.user_time_in_zone(issue.easy_due_date_time) if issue.respond_to?(:easy_due_date_time) && !issue.easy_due_date_time.nil?
    return_end_date ||= issue.due_date
    return_end_date ||= issue.start_date
    return return_end_date
  end

  def get_issue_ical_location(issue)
    return nil #due to weird method

    if (cf_location = issue.custom_value_for(4))
      cf_location.cast_value
    else
      nil
    end
  end

  def load_icalendar(uri, timeout = 15)
    if uri.is_a?(String)
      load_icalendar_from_url(uri)
    else
      Icalendar::Calendar.parse(uri, timeout).first
    end
  end

  def load_icalendar_from_url(url, timeout = 15)
    Timeout::timeout(timeout) {
      return Icalendar::Calendar.parse(open(url, { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE })).first
    }
  end

  def holidays_from_icalendar(icalendar)
    icalendar.events.map do |e|
      name = e.summary
      name = I18n.t(:label_easy_user_working_time_calendar_explanatory_notes_holiday) unless name.present?
      EasyUserTimeCalendarHoliday.new(name: name, holiday_date: e.dtstart, is_repeating: e.rrule.first.try(:frequency) == 'YEARLY', ical_uid: e.uid)
    end
  end

  def icalendar_from_holidays(holidays)
    icalendar = Icalendar::Calendar.new
    icalendar.append_custom_property('METHOD', 'PUBLISH')
    icalendar.append_custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'TRUE')
    holidays.each do |h|
      icalendar.event do |e|
        e.uid     = h.ical_uid || generate_ical_event_uid
        e.dtstart = Icalendar::Values::Date.new(h.holiday_date)
        e.dtend   = Icalendar::Values::Date.new(h.holiday_date + 1.day)
        e.summary = h.name
        e.append_custom_property('rrule', 'FREQ=YEARLY;INTERVAL=1') if h.is_repeating?
      end
    end
    icalendar
  end

  def holidays_to_ical(holidays)
    icalendar_from_holidays(holidays).to_ical
  end

  def generate_ical_event_uid
    Icalendar::Event.new.uid
  end

  # request + organizer = invitation for meeting
  # publish - organizer = calendar event
  #
  def issue_to_invitation(issue, _options = {})
    icalendar = Icalendar::Calendar.new
    event     = Icalendar::Event.new

    event.summary       = issue.subject
    event.description   = Sanitize.clean(issue.description.to_s, output: :html).strip unless issue.description.nil?
    event.created       = Icalendar::Values::Date.new(issue.created_on.to_date)
    event.last_modified = issue.updated_on.to_datetime unless issue.updated_on.nil?
    event.contact       = Icalendar::Values::CalAddress.new("MAILTO:#{issue.assigned_to.mail}", { 'CN' => issue.assigned_to.to_s }) unless issue.assigned_to.nil?
    event.uid           = generate_ical_event_uid
    event.sequence      = issue.lock_version
    event.url           = issue_url(issue)

    issue_to_invitation_as_calendar_event(issue, icalendar, event)

    icalendar.add_event(event)
    icalendar.to_ical
  end

  # Due_date: 22.8.2014
  #   Outlook: with "all day" flag => 21.8.2014
  #            without => 22.8.2014
  #            - same with date and datetime
  #
  def issue_to_invitation_as_calendar_event(issue, icalendar, event)
    icalendar.append_custom_property('METHOD', 'REQUEST')
    #icalendar.publish

    if issue.start_date
      event.dtstart = Icalendar::Values::Date.new(issue.start_date)
    end
    if issue.due_date
      event.dtend = Icalendar::Values::Date.new(issue.due_date)
    end
  end

  def easy_attendances_to_ical(attendances, options = {})
    icalendar = Icalendar::Calendar.new
    icalendar.append_custom_property('METHOD', 'PUBLISH')
    icalendar.append_custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'TRUE')
    attendances.each do |attendance|
      icalendar = easy_attendance_to_ical_obj(icalendar, attendance)
    end
    icalendar.to_ical
  end

  def easy_attendance_to_ical_obj(icalendar, attendance)
    icalendar.event do |e|

      e.dtstart = EasyUtils::IcalendarUtils.to_ical_datetime(attendance.arrival)

      if attendance.departure
        e.dtend = EasyUtils::IcalendarUtils.to_ical_datetime(attendance.departure)
      else
        e.dtend = e.dtstart
      end

      e.organizer   = "mailto:#{attendance.user.mail}" if attendance.user.mail.present?
      e.summary     = "#{attendance.user.name} | #{attendance.easy_attendance_activity.name}"
      e.description = Sanitize.clean(attendance.description.to_s, output: :html).strip
    end

    icalendar
  end

end
