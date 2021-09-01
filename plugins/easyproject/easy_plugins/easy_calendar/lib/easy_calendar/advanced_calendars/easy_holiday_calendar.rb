module EasyCalendar
  module AdvancedCalendars
    class EasyHolidayCalendar < EasyAdvancedCalendar
      def self.label; :button_easy_user_working_time_calendar_holidays; end
      def self.runtime_permissions; User.current.current_working_time_calendar; end

      def events(start_date, end_date)
        wc = EasyUserTimeCalendar.preload(:holidays, :parent => :holidays).find_by(:user_id => User.current.id)
        return [] unless wc
        user = User.current
        temp = {}
        start_date.to_date.upto(end_date.to_date) do |day|
          if (holiday = wc.holiday(day))
            temp[day] = holiday
          end
        end
        temp.map do |day, event|
          start = DateTime.parse(day.to_s)
          events = {
            id: "easy_holiday_event-#{event.id}",
            event_type: 'easy_holiday_event',
            title: event.name.to_s,
            start: user.user_time_in_zone(start).iso8601,
            end: user.user_time_in_zone(start).end_of_day.iso8601,
            color: '#F6CEF5',
            border_color: '#F6CEF5',
            all_day: true
          }
          events[:url] = @controller.edit_user_path(user, :tab => 'working_time') if user.admin?
          events
        end
      end
    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyHolidayCalendar)
