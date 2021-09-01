class EasyAttendanceCalendarEvent < EasyCalendarEvent

  def attributes
    super.tap do |attrs|
      attrs['url'] = nil if include_url?
      attrs['confirmed'] = nil if confirmed
      attrs['need_approve'] = nil
      attrs['limit_exceeded'] = nil
      attrs['easy_attendance_activity_id'] = nil
    end
  end

  def read_attribute_for_serialization(attr)
    return send(:path) if attr == 'url'
    super
  end

  def id
    uid
  end

  def title
    t = object.easy_attendance_activity.name
    t += " - #{object.description}" if object.description.present?
    t
  end

  def confirmed
    object.approved?
  end

  def starts_at
    object.arrival
  end

  def ends_at
    object.departure
  end

  def event_type
    # 'availability_meeting' in old version
    'easy_attendance'
  end

  def editable
    User.current.admin? || object.can_edit?
  end

  def need_approve
    object.need_approve?
  end

  def easy_attendance_activity_id
    object.easy_attendance_activity_id
  end

  def limit_exceeded
    !object.easy_attendance_vacation_limit_valid?
  end

  def all_day?
    # true in old version
    false
  end

  def is_author?
    object.user_id == User.current.id
  end

  def include_url?
    editable
  end

  def location
  end

  def path
    Rails.application.routes.url_helpers.easy_attendance_path(object)
  end

  def url
    Rails.application.routes.url_helpers.easy_attendance_url(object, host: self.class.host)
  end

  def organizer
    object.try(:user).try(:mail)
  end

end
