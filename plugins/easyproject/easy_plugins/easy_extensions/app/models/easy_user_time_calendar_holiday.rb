class EasyUserTimeCalendarHoliday < ActiveRecord::Base

  include Redmine::SafeAttributes
  safe_attributes 'name', 'calendar_id', 'holiday_date', 'is_repeating', 'ical_uid'

  default_scope { order("#{EasyUserTimeCalendarHoliday.table_name}.is_repeating DESC, #{EasyUserTimeCalendarHoliday.table_name}.holiday_date ASC") }

  belongs_to :calendar, :class_name => 'EasyUserTimeCalendar', :foreign_key => 'calendar_id', :touch => true

  validates_length_of :name, :in => 0..255
  validates :calendar_id, :holiday_date, :name, :presence => true
  validates :ical_uid, :uniqueness => { :scope => :calendar_id }

end
