require 'easy_calendar/easy_calendar_events/easy_calendar_event'
class EasyGanttResourceCalendarEvent < EasyCalendarEvent

  def title
    object.issue&.subject
  end

  def starts_at
    if all_day?
      object.date
    else
      User.current.user_time_in_zone(object.date.to_datetime).change(hour: object.start.hour, min: object.start.min)
    end
  end

  def ends_at
    starts_at.advance(hours: object.hours)
  end

  def all_day?
    object.start.nil?
  end

  def location
    url
  end

  def url(_context = nil)
    object.issue && Rails.application.routes.url_helpers.issue_url(object.issue, self.class.default_url_options).to_s
  end

  def organizer
    object.issue&.author&.name
  end

end
