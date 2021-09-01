class EasyAttendanceActivityUserLimit < ActiveRecord::Base

  belongs_to :easy_attendance_activity
  belongs_to :user

  validates :user_id, :easy_attendance_activity_id, :presence => true
  validates :easy_attendance_activity_id, :uniqueness => { :scope => :user_id }
  validates :days, :numericality => { :greater_than_or_equal_to => 0 }
  validates :accumulated_days, :numericality => true

  def total_user_days
    self.days + self.accumulated_days
  end

  # returns difference between current user activity days and limit value
  def limit_days_difference_per_year(year)
    total_user_days - self.easy_attendance_activity.sum_in_days_easy_attendance(self.user, year)
  end

  def save_accumulated_days
    return false if (current_difference = limit_days_difference_per_year(Date.today.year)) <= 0
    self.accumulated_days = current_difference
    self.save
  end

end
