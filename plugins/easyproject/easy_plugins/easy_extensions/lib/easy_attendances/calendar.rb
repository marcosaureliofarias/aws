module EasyAttendances

  class Calendar < Redmine::Helpers::Calendar

    attr_reader :events

    def events=(events)
      @events                  = events
      @ending_events_by_days   = @events.group_by { |event| event.due_date(User.current) }
      @starting_events_by_days = @events.group_by { |event| event.start_date(User.current) }

      days = Hash.new { |hash, key| hash[key] = [] }
      @startdt.upto(@enddt) do |day|
        days[day.cweek] << day
      end

      @sorted_events = Hash.new
      days.each do |week, days|
        days.each do |day|
          @sorted_events[day] = EasyAttendances::EasyAttendanceCalendarDay.new(day, ((@ending_events_by_days[day] || []) + (@starting_events_by_days[day] || [])).uniq)
        end
      end
    end

    def events_on(day)
      Array(@sorted_events[day])
    end

  end
end
