module EasyExtensions::TimeCalculations

  def beginning_of_halfyear
    beginning_of_month.change(:month => [7, 1].detect { |m| m <= self.month })
  end

  alias :at_beginning_of_halfyear :beginning_of_halfyear

  def end_of_halfyear
    beginning_of_month.change(:month => [6, 12].detect { |m| m >= self.month }).end_of_month
  end

  alias :at_end_of_halfyear :end_of_halfyear

end

class Date
  include EasyExtensions::TimeCalculations

  def next_week_day(day)
    day        = day % 7
    difference = (day - self.wday)
    difference += 7 if difference <= 0
    self + difference
  end

  def closest_week_day(days = [])
    return self + 7 unless days.is_a?(Array) && days.any?
    days.map { |d| self.next_week_day(d) }.min
  end

  def increase_date(count, use_working_time_calendar = false)
    if use_working_time_calendar && (calendar = EasyUserTimeCalendar.default)
      calendar.shift_by_working_days(count, start_date: self.dup, max_shift: 365)
    else
      self + count
    end
  end

  def easy_prev_week(user = User.current)
    first_wday = user.current_working_time_calendar.first_wday
    self - 7 - ((self.cwday - first_wday) % 7)
  end

  class << self

    def safe_parse(*args)
      begin
        parse(*args)
      rescue TypeError, ArgumentError
        nil
      end
    end

  end

end

class DateTime
  include EasyExtensions::TimeCalculations
end

class Time
  include EasyExtensions::TimeCalculations
end
