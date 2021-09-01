require 'delegate'
class EasyEntityActivityDecorator < SimpleDelegator

  def start_date
    start_time && User.current.user_time_in_zone(start_time)
  end

  def end_date
    end_time && User.current.user_time_in_zone(end_time)
  end

  def date
    start_date&.to_date
  end

  def user_start_time
    start_date ? start_date.strftime('%H:%M') : ''
  end

  def user_end_time
    end_date ? end_date.strftime('%H:%M') : ''
  end

  def categories
    EasyEntityActivityCategory.sorted.collect { |x| [x.name, x.id] }
  end

  def user_attendees
    selected = easy_entity_activity_attendees.where(entity_type: 'Principal').
        map { |eea| { id: eea.entity_id, value: eea.to_s } }
    selected << { id: User.current.id, value: User.current.name } if selected.empty?
    selected
  end

  def types
    {}
  end
end