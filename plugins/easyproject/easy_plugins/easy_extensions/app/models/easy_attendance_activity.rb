require 'ipaddr'

class EasyAttendanceActivity < ActiveRecord::Base
  include Redmine::SafeAttributes

  safe_attributes 'name',
                  'position',
                  'at_work',
                  'is_default',
                  'internal_name',
                  'non_deletable',
                  'project_mapping',
                  'mapped_project_id',
                  'mapped_time_entry_activity_id',
                  'mail',
                  'color_schema',
                  'approval_required',
                  'use_specify_time',
                  'reorder_to_position',
                  'system_activity'

  has_many :easy_attendances
  has_many :time_entries, :through => :easy_attendances
  has_many :easy_attendance_activity_user_limits, :dependent => :destroy
  belongs_to :mapped_project, :class_name => 'Project', :foreign_key => 'mapped_project_id'
  belongs_to :mapped_time_entry_activity, :class_name => 'TimeEntryActivity', :foreign_key => 'mapped_time_entry_activity_id'

  validates :name, :presence => true

  acts_as_positioned
  acts_as_easy_translate

  scope :sorted, lambda { order("#{EasyAttendanceActivity.table_name}.position") }
  scope :system_activities, -> { where(system_activity: true) }
  scope :user_activities, -> { where.not(system_activity: true) }

  before_save :check_default

  def self.default
    where(:is_default => true).first
  end

  def self.ip_ranged(in_range)
    if EasyAttendance.enabled?
      plugin_settings = Setting.plugin_easy_attendances
      activity_id     = plugin_settings && plugin_settings["#{in_range ? '' : 'outside_'}ip_range_activity_id"]
      if activity_id.present?
        return EasyAttendanceActivity.find_by(id: activity_id)
      end
    end
  end

  def self.for_ip(ip)
    begin
      return self.default if ip.blank?
      ip = IPAddr.new(ip) if ip.is_a?(String)

      ranges = EasyAttendance.office_ip_range
      return self.default if ranges.blank?

      self.ip_ranged(!ranges.detect { |range| range.include?(ip) }.nil?)
    rescue ArgumentError
      return self.default
    end
  end

  def to_s
    return self.name
  end

  def css_classes
    s = 'easy-attendance-activity'
    s << " #{self.color_schema}"

    return s
  end

  def sum_in_days_timeentry(user, year)
    half_working_hours = user.default_working_hours / 2

    scope = self.time_entries.where(:tyear => year).where(:user_id => user.id)
    scope.all.inject(0.0) do |memo, t|
      hours = t.hours

      if hours <= 0.0
        memo
      else
        if hours <= half_working_hours
          memo += 0.5
        else
          memo += 1
        end
      end
    end
  end

  def sum_in_days_attendance_by_status(user, year, statuses, return_value_in_hours = false)
    beginning_of_year, end_of_year = DateTime.new(year).beginning_of_year, DateTime.new(year).end_of_year

    easy_attendances = user.easy_attendances
    easy_attendances = easy_attendances.where(approval_status: statuses) if approval_required?
    easy_attendances.where(easy_attendance_activity_id: id).between(beginning_of_year, end_of_year).sum_spent_time(user.current_working_time_calendar, return_value_in_hours)
  end

  def sum_in_days_easy_attendance(user, year, return_value_in_hours = false)
    statuses = [EasyAttendance::APPROVAL_APPROVED, EasyAttendance::CANCEL_WAITING, EasyAttendance::CANCEL_REJECTED]
    sum_in_days_attendance_by_status(user, year, statuses, return_value_in_hours)
  end

  def user_waiting_vacation_in_days(user, year)
    return 0.0 unless approval_required?

    sum_in_days_attendance_by_status(user, year, [EasyAttendance::APPROVAL_WAITING]).to_f
  end

  def user_vacation_remaining_in_days(user, year)
    user_vacation_limit_difference_in_days(user, year).to_f
  end

  def easy_attendance_activity_user_limit(user = nil)
    user ||= User.current
    user.easy_attendance_activity_user_limits.find_by_easy_attendance_activity_id(self.id)
  end

  def user_vacation_limit_in_days(user)
    user_vacation_limit_to_days(easy_attendance_activity_user_limit(user))
  end

  def user_vacation_limit_in_days_with_empty(user)
    if (limit = easy_attendance_activity_user_limit(user))
      return user_vacation_limit_to_days(limit)
    end
    return nil
  end

  def global_vacation_limit_difference_in_days(user, year)
    return nil unless EasyAttendance.enabled? && !Setting.plugin_easy_attendances.nil? && !Setting.plugin_easy_attendances['easy_attendance_activity_user_limit'].nil?

    global_limit = Setting.plugin_easy_attendances['easy_attendance_activity_user_limit'][self.id.to_s]
    return nil if global_limit.blank?

    global_limit.to_i - self.sum_in_days_easy_attendance(user, year)
  end

  def user_vacation_limit_difference_in_days(user, year)
    user_limit = easy_attendance_activity_user_limit(user).try(:limit_days_difference_per_year, year)
    return global_vacation_limit_difference_in_days(user, year) if user_limit.nil?

    user_limit
  end

  def specify_by_time?
    (use_specify_time.nil?) ? at_work? : use_specify_time?
  end

  private

  def user_vacation_limit_to_days(limit)
    limit.try(:days).to_f
  end

  def check_default
    if self.is_default? && self.is_default_changed?
      EasyAttendanceActivity.update_all(:is_default => false)
    end
  end

end
