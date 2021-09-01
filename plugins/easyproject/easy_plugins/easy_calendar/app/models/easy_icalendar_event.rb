class EasyIcalendarEvent < ActiveRecord::Base
  belongs_to :easy_icalendar

  validates :easy_icalendar, presence: true
  validates :dtstart, :uid, presence: true

  scope :from_calendars, -> (ical_ids) {
    joins(:easy_icalendar).where(easy_icalendars: {id: ical_ids}).preload(:easy_icalendar)
  }

  scope :user_events, -> (user_id) {
    joins(:easy_icalendar).
    where(easy_icalendars: { user_id: user_id }).
    where('easy_icalendars.visibility <> ?', EasyIcalendar.visibilities[:is_invisible]).
    preload(:easy_icalendar)
  }

  scope :between, -> (start_time, end_time) {
    if start_time && end_time
      where(in_period(start_time, end_time))
    else
      all
    end
  }

  def self.in_period(start_time, end_time)
    dtstart_condition(start_time, end_time).or(dtend_condition(start_time, end_time))
  end

  def self.dtstart_condition(start_time, end_time)
    arel_table[:dtstart].lteq(end_time).and(arel_table[:dtstart].gteq(start_time))
  end

  def self.dtend_condition(start_time, end_time)
    arel_table[:dtend].lteq(end_time).and(arel_table[:dtend].gteq(start_time))
  end
end
