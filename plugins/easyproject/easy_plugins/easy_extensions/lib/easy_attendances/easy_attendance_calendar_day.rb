module EasyAttendances
  class EasyAttendanceCalendarDay

    def initialize(day, events)
      @day           = day
      @sorted_events = ActiveSupport::OrderedHash.new
      grouped_events = events.group_by(&:user)

      grouped_events.each do |user_and_events|
        @sorted_events[user_and_events.first] = user_and_events.last.sort_by(&:arrival)
      end
    end

    def events
      @sorted_events
    end

  end
end
