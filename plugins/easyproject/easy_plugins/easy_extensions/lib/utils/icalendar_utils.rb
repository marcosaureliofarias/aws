module EasyUtils
  module IcalendarUtils
    extend self

    # BYDAY have format: [([plus] ordwk / minus ordwk)] weekday
    def recurring_by_day_to_custom_days(by_day)
      Array(by_day).map do |day|
        case day.last(2).upcase
        when 'MO' then
          1
        when 'TU' then
          2
        when 'WE' then
          3
        when 'TH' then
          4
        when 'FR' then
          5
        when 'SA' then
          6
        when 'SU' then
          0
        end
      end
    end

    def recurring_custom_days_to_by_day(custom_days)
      Array(custom_days).map do |day|
        case day.to_i
        when 1 then
          'MO'
        when 2 then
          'TU'
        when 3 then
          'WE'
        when 4 then
          'TH'
        when 5 then
          'FR'
        when 6 then
          'SA'
        when 0 then
          'SU'
        end
      end
    end

    # Last in repeatings is 5
    def recurring_by_set_position_to_custom_order(by_set_position)
      pos = by_set_position.first.to_i
      case pos
      when 1..4
        pos
      when -1
        5
      else
        1
      end
    end

    def recurring_custom_order_to_by_set_position(pos)
      pos = pos.to_i
      case pos
      when 1..4
        [pos]
      when 5
        [-1]
      else
        [1]
      end
    end

    def recurring_to_custom_order(by_set_position, by_day)
      order = if by_set_position
                recurring_by_set_position_to_custom_order(by_set_position)
              elsif by_day
                day = by_day.first
                day = day.match(/(\d{0,2})[a-z]{2}/i)
                day[1].to_i if day
              end
      order || 1
    end

    # RRULE has also defined negative number
    def recurring_to_monthly_day(by_month_day)
      Array(by_month_day).each do |value|
        value = value.to_i
        return value if value >= 1 && value <= 31
      end

      1
    end

    def recurring_to_month_num(by_month)
      Array(by_month).each do |value|
        value = value.to_i
        return value if value >= 1 && value <= 12
      end

      1
    end

    # All day event is stil saved as Time shifted to DB time zone
    def to_ical_date(value)
      return unless value

      unless value.is_a?(Date)
        zone  = User.current.time_zone
        value = zone ? value.in_time_zone(zone) : (value.utc? ? value.localtime : value)
      end

      Icalendar::Values::Date.new(value)
    end

    def to_ical_datetime(value)
      value.to_datetime.utc.strftime('%Y%m%dT%H%M%SZ') if value.present?
    rescue ArgumentError
    end

    # Argument `rrule` must be `[Open]Struct` with keys:
    #   frequency, until, count, interval, by_second, by_minute, by_hour,
    #   by_day, by_month_day, by_year_day, by_week_number, by_month,
    #   by_set_position, week_start
    #
    # Primary implemented for Outlook 2016 and Thunderbird
    #
    def repeating_from_ical(rrule)
      repeat_settings = {}
      interval        = (rrule.interval ? rrule.interval : 1)

      case rrule.frequency.to_s.upcase
      when 'DAILY'
        repeat_settings['period']       = 'daily'
        repeat_settings['daily_option'] = 'each'
        repeat_settings['daily_each_x'] = interval

      when 'WEEKLY'
        repeat_settings['period']    = 'weekly'
        repeat_settings['week_days'] = recurring_by_day_to_custom_days(rrule.by_day)

      when 'MONTHLY'
        repeat_settings['period']         = 'monthly'
        repeat_settings['monthly_period'] = interval

        if rrule.by_month_day
          repeat_settings['monthly_option'] = 'xth'
          repeat_settings['monthly_day']    = recurring_to_monthly_day(rrule.by_month_day)
        elsif rrule.by_day
          repeat_settings['monthly_option']       = 'custom'
          repeat_settings['monthly_custom_order'] = recurring_to_custom_order(rrule.by_set_position, rrule.by_day)
          repeat_settings['monthly_custom_day']   = recurring_by_day_to_custom_days(rrule.by_day).first
        end

      when 'YEARLY'
        repeat_settings['period']        = 'yearly'
        repeat_settings['yearly_period'] = interval

        if rrule.by_month_day
          repeat_settings['yearly_option'] = 'date'
          repeat_settings['yearly_month']  = recurring_to_month_num(rrule.by_month)
          repeat_settings['yearly_day']    = recurring_to_monthly_day(rrule.by_month_day)
        else
          repeat_settings['yearly_option']       = 'custom'
          repeat_settings['yearly_custom_order'] = recurring_to_custom_order(rrule.by_set_position, rrule.by_day)
          repeat_settings['yearly_custom_day']   = recurring_by_day_to_custom_days(rrule.by_day).first
          repeat_settings['yearly_custom_month'] = recurring_to_month_num(rrule.by_month)
        end

      else
        return
      end

      if rrule.count
        repeat_settings['endtype']         = 'count'
        repeat_settings['endtype_count_x'] = rrule.count.to_i
      elsif rrule.until
        repeat_settings['endtype'] = 'date'
        repeat_settings['end_date'] = Date.parse(rrule.until) rescue DateTime.now
      else
        repeat_settings['endtype'] = 'count'
        # repeat_settings['endtype_count_x'] = EasyMeeting::MAX_BIG_RECURRING_COUNT
        repeat_settings['endtype_count_x'] = 100
      end

      repeat_settings['simple_period'] = 'custom'
      repeat_settings
    end

    def repeating_to_ical(repeat_settings)
      rrule = OpenStruct.new(frequency: nil, until: nil, count: nil, interval: nil, by_second: nil, by_minute: nil, by_hour: nil, by_day: nil, by_month_day: nil, by_year_day: nil, by_week_number: nil, by_month: nil, by_set_position: nil, week_start: nil)
      return rrule if !repeat_settings.is_a?(Hash)

      case repeat_settings['period']
      when 'daily'
        rrule.frequency = 'DAILY'
        rrule.interval  = repeat_settings['daily_each_x'].presence || 1

      when 'weekly'
        rrule.frequency = 'WEEKLY'
        rrule.by_day    = recurring_custom_days_to_by_day(repeat_settings['week_days'])

      when 'monthly'
        rrule.frequency = 'MONTHLY'
        rrule.interval  = repeat_settings['monthly_period'].presence || 1

        if repeat_settings['monthly_option'] == 'xth'
          rrule.by_month_day = [repeat_settings['monthly_day']]
        else
          rrule.by_set_position = recurring_custom_order_to_by_set_position(repeat_settings['monthly_custom_order'])
          rrule.by_day          = recurring_custom_days_to_by_day(repeat_settings['monthly_custom_day'])
        end

      when 'yearly'
        rrule.frequency = 'YEARLY'
        rrule.interval  = repeat_settings['yearly_period'].presence || 1

        if repeat_settings['yearly_option'] == 'date'
          rrule.by_month     = [repeat_settings['yearly_month']]
          rrule.by_month_day = [repeat_settings['yearly_day']]
        else
          rrule.by_set_position = recurring_custom_order_to_by_set_position(repeat_settings['yearly_custom_order'])
          rrule.by_day          = recurring_custom_days_to_by_day(repeat_settings['yearly_custom_day'])
          rrule.by_month        = [repeat_settings['yearly_custom_month']]
        end
      end

      if repeat_settings['endtype'] == 'count'
        rrule.count = repeat_settings['endtype_count_x']
      else
        rrule.until = to_ical_datetime(repeat_settings['end_date'])
      end

      rrule
    end

    def get_end(dtstart, dtend, duration)
      if dtend
        dtend.value
      elsif duration
        dtstart.value + parse_ical_duration(duration)
      else
        dtstart.value
      end
    end

    # dur-value  = (["+"] / "-") "P" (dur-date / dur-time / dur-week)
    #
    # dur-date   = dur-day [dur-time]
    # dur-time   = "T" (dur-hour / dur-minute / dur-second)
    # dur-week   = 1*DIGIT "W"
    # dur-hour   = 1*DIGIT "H" [dur-minute]
    # dur-minute = 1*DIGIT "M" [dur-second]
    # dur-second = 1*DIGIT "S"
    # dur-day    = 1*DIGIT "D"
    def parse_ical_duration(duration)
      result = 0.days
      result += duration.weeks.weeks
      result += duration.days.days
      result += duration.hours.hours
      result += duration.minutes.minutes
      result += duration.seconds.seconds
      result
    end

  end
end
