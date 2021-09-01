class EasyUserTimeCalendarException < ActiveRecord::Base

  include Redmine::SafeAttributes

  belongs_to :calendar, :class_name => 'EasyUserTimeCalendar', :foreign_key => 'calendar_id', :touch => true

  validates_numericality_of :working_hours, :allow_nil => false, :message => :invalid, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0
  validates :calendar_id, :exception_date, :presence => true

  safe_attributes 'calendar_id', 'exception_date', 'working_hours'

end
