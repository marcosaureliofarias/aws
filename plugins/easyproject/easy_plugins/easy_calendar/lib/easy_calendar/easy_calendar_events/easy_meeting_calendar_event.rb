class EasyMeetingCalendarEvent < EasyCalendarEvent

  def attributes
    attrs = super
    attrs['confirmed'] = nil if confirmed
    attrs['is_private'] = nil
    if include_location?
      attrs['location'] = nil
      attrs['place_name'] = nil
      attrs['room'] = nil
    end
    attrs['project'] = nil
    attrs
  end

  def uid
    object.uid
  end

  def id
    "easy_meeting-#{object.id}"
  end

  def etag
    object.etag
  end

  def title
    object.visible? ? object.name : I18n.t('easy_calendar.label_private_event')
  end

  def description
    is_viewable_meeting? ? object.description : ''
  end

  def confirmed
    object.accepted_by?(User.current)
  end

  def starts_at
    object.start_time
  end

  def ends_at
    object.end_time
  end

  def event_type
    if editable
      "meeting"
    else
      is_viewable_meeting? ? 'meeting_detail' : 'availability_meeting'
    end
  end

  def editable
    is_viewable_meeting? && object.editable?
  end

  def place_name
    object.place_name.presence
  end

  def room
    object.easy_room&.name
  end

  def project
    object.project&.name
  end

  def all_day?
    object.all_day
  end

  def is_author?
    object.author_id == User.current.id
  end

  def is_viewable_meeting?
    @is_viewable_meeting ||= object.visible_details?
  end

  def include_url?
    editable || is_viewable_meeting?
  end

  def include_location?
    editable || is_viewable_meeting?
  end

  def location
    object.try(:easy_room).try(:name).presence || object.place_name
  end

  def url
    Rails.application.routes.url_helpers.easy_meeting_url(object, host: self.class.host)
  end

  def path
    Rails.application.routes.url_helpers.easy_meeting_path(object)
  end

  def organizer
    if (a = object.author)
      return "MAILTO:#{a.mail}"
    end
  end

  def attendees
    object.external_mails.map{|u| "MAILTO:#{u}"}
  end

  def is_private
    !is_viewable_meeting?
  end

  def to_ical
    event = super
    event.description = object.description.to_s

    if (my_invitation = object.invitation_for(User.current)).is_a?(Array)
      Icalendar::Alarm.parse(my_invitation.alarms.join) do |alarm|
        event.add_alarm alarm
      end
    else
      event.alarm do |a|
        a.summary =  '5 minutes before'
        a.trigger = '-PT05M'
      end
      event.alarm do |a|
        a.summary = '30 minutes before'
        a.trigger = '-PT30M'
      end
    end

    object.easy_invitations.each do |inv|
      stat = inv.accepted? ? 'ACCEPTED' : 'DECLINED' unless inv.accepted.nil?
      prop = {'PARTSTAT' => stat, 'CN' => inv.user.name}

      if inv.user_id == object.author_id
        # prop['ROLE'] = 'CHAIR'
        next
      end
      attendee = Icalendar::Values::CalAddress.new("MAILTO:#{inv.user.mail}", prop)
      event.append_attendee(attendee)
    end

    event
  end

end
