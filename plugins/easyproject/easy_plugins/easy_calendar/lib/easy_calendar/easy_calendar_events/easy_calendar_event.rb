require 'icalendar/tzinfo'

class EasyCalendarEvent
  include ActiveModel::Serializers::JSON

  SERIALIZED_ATTRIBUTES = [:title, :start, :end, :all_day, :id, :event_type, :editable]

  attr_reader :object

  def serializable_hash(options = {})
    Hash[super.to_a.map { |k, v| [k.to_s.camelize(:lower), v] }]
  end

  def attributes
    attrs = SERIALIZED_ATTRIBUTES.map(&:to_s).each_with_object(nil).to_h
    attrs['url'] = nil if include_url?
    attrs
  end

  def initialize(object)
    @object = object
  end

  def self.create(object)
    "#{object.class.name}CalendarEvent".constantize.new(object)
  end

  def uid
    "availability-#{self.class.name.underscore.dasherize}-#{object.id}"
  end

  def title
    raise NotImplementedError
  end

  def starts_at
    raise NotImplementedError
  end

  def ends_at
    raise NotImplementedError
  end

  def editable
    raise NotImplementedError
  end

  def all_day
    all_day?
  end

  def all_day?
    raise NotImplementedError
  end

  def location
    raise NotImplementedError
  end

  def url(context = nil)
    raise NotImplementedError
  end

  def include_url?
    raise NotImplementedError
  end

  def organizer
    raise NotImplementedError
  end

  def place_name
    raise NotImplementedError
  end

  def room
    raise NotImplementedError
  end

  def project
    raise NotImplementedError
  end

  def attendees
    []
  end

  def start
    User.current.user_time_in_zone(starts_at).iso8601
  end

  def end
    User.current.user_time_in_zone(ends_at).iso8601
  end

  def to_ical_datetime(value)
    value.to_datetime.utc.strftime('%Y%m%dT%H%M%SZ') if value.present?
  rescue ArgumentError
  end

  # All day event is stil saved as Time shifted to DB time zone
  def to_ical_date(value)
    return unless value

    unless value.is_a?(Date)
      zone = User.current.time_zone
      value = zone ? value.in_time_zone(zone) : (value.utc? ? value.localtime : value)
    end

    Icalendar::Values::Date.new(value)
  end

  def to_ical
    event = Icalendar::Event.new
    event.uid          = uid
    event.url          = url
    event.summary      = title
    event.location     = location

    if all_day?
      event.dtstart = to_ical_date(starts_at)
      event.dtend   = to_ical_date(ends_at)
    else
      event.dtstart = to_ical_datetime(starts_at)
      event.dtend   = to_ical_datetime(ends_at)
    end

    event.organizer    = organizer
    event.attendee     = attendees
    event.ip_class     = 'PUBLIC'
    event
  end

  def to_icalendar
    tzinfo = TZInfo::Timezone.get(User.current.time_zone && User.current.time_zone.tzinfo.identifier || 'UTC')
    timezone = tzinfo.ical_timezone(starts_at)

    calendar = Icalendar::Calendar.new
    calendar.add_timezone(timezone)
    calendar.add_event(to_ical)
    calendar
  end

  def self.default_url_options
    Mailer.default_url_options
  end

  def self.host
    self.default_url_options[:host]
  end

  private

  def read_attribute_for_serialization(attr)
    return send(:path) if attr == 'url'
    super
  end

end
