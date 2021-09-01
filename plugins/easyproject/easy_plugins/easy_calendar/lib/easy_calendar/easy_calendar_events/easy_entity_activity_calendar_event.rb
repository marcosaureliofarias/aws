class EasyEntityActivityCalendarEvent < EasyCalendarEvent
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  def attributes
    attrs = super
    attrs['entity_id'] = nil
    attrs['entity_type'] = nil
    attrs
  end

  def id
    "easy_entity_activity-#{object.id}"
  end

  def title
    "#{object.entity.to_s}: #{object.category.name}"
  end

  def starts_at
    object.start_time
  end

  def ends_at
    object.end_time
  end

  def event_type
    'easy_entity_activity'
  end

  def entity_id
    object.entity_id
  end

  def entity_type
    object.entity_type
  end

  def all_day?
    object.all_day
  end

  def is_author?
    object.author_id == User.current.id
  end

  def editable
    return true if User.current.admin? || is_author?
    object.entity.editable?
  end

  def include_url?
    editable
  end

  def location
  end

  def end
    end_time = ends_at.nil? ? starts_at + EasyEntityActivity::DELTA.minutes : ends_at
    User.current.user_time_in_zone(end_time).iso8601
  end

  def path
    polymorphic_path(object.entity)
  end

  def url
    polymorphic_url(object.entity, only_path: false, host: Mailer.default_url_options[:host])
  end

  def organizer
  end

end