Rys::Patcher.add('EasyUserTimeCalendar') do

  apply_if_plugins :easy_extensions

  included do

    def unshift_working_day(delta, end_date = nil, max_unshift = 66)
      end_date ||= Date.today
      start_date = end_date - delta.days

      if working_day?(start_date) || max_unshift <= 0
        start_date
      elsif delta > 0
        unshift_working_day(1, start_date, max_unshift - 1)
      else
        unshift_working_day(-1, start_date, max_unshift - 1)
      end
    end

    def unshift_by_working_days(delta, end_date: nil, max_shift: 66)
      end_date ||= Date.today
      start_date = end_date - delta.days

      working_days_shift = working_days(start_date, end_date - 1)
      minimal_remaining_shift = delta - working_days_shift

      while minimal_remaining_shift > 0
        next_end_date = start_date
        start_date = unshift_working_day(minimal_remaining_shift, next_end_date, max_shift + minimal_remaining_shift)
        working_days_shift += working_days(start_date, next_end_date - 1)
        minimal_remaining_shift = delta - working_days_shift
      end

      start_date
    end

  end

end
