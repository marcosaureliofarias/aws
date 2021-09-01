class EasyHelpdeskProjectSla < ActiveRecord::Base

  belongs_to :easy_helpdesk_project
  belongs_to :priority, :class_name => 'IssuePriority', :foreign_key => 'priority_id'
  belongs_to :easy_user_working_time_calendar, :class_name => 'EasyUserTimeCalendar', :foreign_key => 'easy_user_working_time_calendar_id'
  belongs_to :tracker
  has_many :issues

  scope :sorted, lambda { order(:position) }

  validates :hours_to_solve, numericality: true, allow_nil: true
  validates :hours_to_response, numericality: true, allow_nil: true
  validates :keyword, :length => { :maximum => 255 }
  validate :validate_presence_of_hours_fields
  validate :validate_hours_mode

  def hours_mode_from_value
    parse_hours_value(hours_mode_from)
  end

  def hours_mode_to_value
    parse_hours_value(hours_mode_to)
  end

  private

  def parse_hours_value(value)
    values = value.to_s.split(':').map(&:to_i)
    hours = values[0] || 0
    minutes = values[1] || 0
    hours + (minutes / 60.0)
  end

  def validate_presence_of_hours_fields
    if hours_to_response.nil? && hours_to_solve.nil?
      errors.add(:base, l(:error_easy_helpdesk_project_sla_hours_fields_empty))
    end
  end

  def validate_hours_mode
    if hours_mode_from_value > hours_mode_to_value
      errors.add(:base, l(:error_easy_sla_hours_mode_greater_than, title: title, from: hours_mode_from, to: hours_mode_to))
    end
  end
end
