module EasyCalendar
  module AdvancedCalendars
    class EasyAttendanceCalendar < EasyAdvancedCalendar
      def self.label
        'easy_attendance.label'
      end

      def self.permissions; :view_easy_attendances; end

      def events(start_date, end_date)
        user = User.current
        attendances = user.easy_attendances.includes(:easy_attendance_activity).where(:easy_attendance_activities => {:at_work => false})
        attendances = attendances.between(start_date, end_date) if start_date && end_date
        events = attendances.to_a

        events.map! do |event|
          options = {
            id:           "easy_attendance-#{event.id}",
            event_type:   'easy_attendance',
            location:     event.description,
            title:        event.easy_attendance_activity.name,
            start:        user.user_time_in_zone(event.arrival).iso8601,
            end:          user.user_time_in_zone(event.departure).iso8601,
            all_day:      true,
            color:        '#F7A4A4',
            border_color: '#F07777',
            confirmed:    event.approved?,
            need_approve: event.need_approve?,
          }

          options[:url] = @controller.edit_easy_attendance_path(event, back_url: @controller.back_url) if event.can_edit?(user)
          options
        end
        events
      end

    end
  end
end

EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyAttendanceCalendar) if Redmine::Plugin.installed?(:easy_attendances)
