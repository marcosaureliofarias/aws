class EasyIcalendarEventCalendarEvent < EasyCalendarEvent

  def attributes
    attrs = super
    attrs['all_day'] = nil
    attrs['ical_name'] = nil
    attrs['is_private'] = nil
    attrs['sync_date'] = nil
    attrs['ical_id'] = nil if is_author?
    attrs['event_id'] = nil
    attrs
  end

  def id
    "easy_ical_event-#{object.uid}"
  end

  def title
    if is_private
      I18n.t('easy_calendar.label_private_event')
    else
      object.summary
    end
  end

  def starts_at
    object.dtstart
  end

  def ends_at
    object.dtend
  end

  def end
    end_time = ends_at.nil? ? starts_at + EasyEntityActivity::DELTA.minutes : ends_at
    User.current.user_time_in_zone(end_time).iso8601
  end

  def event_type
    'ical_event'
  end

  def editable
    false
  end

  def all_day?
    # TODO
    # object.custom_property('all_day').first
    false
  end

  def location
    object.location
  end

  def ical_name
    object.easy_icalendar.name
  end

  def ical_id
    object.easy_icalendar.id
  end

  def sync_date
    if (sync_date = object.easy_icalendar.synchronized_at)
      User.current.user_time_in_zone(sync_date).iso8601
    end
  end

  def event_id
    object.id
  end

  def include_url?
    true
  end

  def is_author?
    object.easy_icalendar.user_id == User.current.id
  end

  def url
    object.url
  end

  # see EasyCalendarEvent#read_attribute_for_serialization
  # 'url' attr will be serialized as path
  # for external event 'url' attr should be url
  def path
    url
  end

  def is_private
    return false if is_author?
    object.easy_icalendar.is_private? || object.is_private
  end
end
