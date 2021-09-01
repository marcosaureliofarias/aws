class IssueEasyDuration

  def self.easy_duration_calculate(start_date, due_date)
    calendar = EasyUserWorkingTimeCalendar.default
    return unless calendar

    easy_duration = calendar.working_days(start_date, due_date)

    easy_duration += 1 unless calendar.working_day?(start_date)
    easy_duration += 1 unless calendar.working_day?(due_date)
    easy_duration
  end

  def self.move_date(easy_duration, easy_duration_unit, start_date = nil, due_date = nil)
    return unless start_date || due_date

    days = easy_duration_days_count(easy_duration.to_i, easy_duration_unit)
    calendar = EasyUserWorkingTimeCalendar.default
    return unless calendar

    if start_date
      calendar.shift_by_working_days((days - 1), start_date: start_date)
    elsif due_date
      calendar.unshift_by_working_days((days - 1), end_date: due_date)
    end
  end

  def self.easy_duration_days_count(count, unit)
    case unit
    when 'week'
      count * 5
    when 'month'
      count * 21
    else # 'day'
      count
    end
  end

  def self.time_units
    time_units = [:day, :week, :month]
    time_units.map{ |time_unit| [I18n.t("issue_duration.time_units.#{time_unit.to_s}"),time_unit]}
  end

end
