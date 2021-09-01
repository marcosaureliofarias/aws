module EasyExtensions::TimeRounding

  def round_min_to(minutes)
    if (self.min % minutes) == 0
      return self.change(:sec => 0)
    end
    how_many_in_hours = (60 / minutes.round)
    how_many_in_hours.times.each do |x|
      if self.min < (rounded_min = (x + 1) * minutes.round)
        return (self + (rounded_min - self.min) * 60).change(:sec => 0)
      end
    end
  end

  def round_min_to_quarters
    round_min_to(15)
  end

end

class DateTime
  include EasyExtensions::TimeRounding

  def localtime
    Time.new(self.year, self.month, self.day, self.hour, self.min, self.sec, self.zone).localtime.to_datetime
  end
end

class Time
  include EasyExtensions::TimeRounding
end
