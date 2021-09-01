module EasyCalendar
  module Caldav
    class EasyAttendanceResource < EntityResource

      def getetag
        %{"#{entity.id}-#{entity.updated_at.to_i}"}
      end

      def displayname
        entity.easy_attendance_activity.name
      end

      def getlastmodified
        entity.updated_at.httpdate
      end

      def creationdate
        entity.created_at.iso8601
      end

      def url
        Rails.application.routes.url_helpers.url_for(
          controller: 'easy_attendances',
          action:     'show',
          id:         entity.id,
          only_path:  false,
          host: Mailer.default_url_options[:host],
          port: Mailer.default_url_options[:port]
        )
      end

      def _calendar_data
        event = Icalendar::Event.new
        event.uid      = entity.id.to_s
        event.url      = url.to_s
        event.location = url.to_s
        event.summary  = entity.easy_attendance_activity.name
        event.ip_class = 'PUBLIC'
        event.dtstart  = EasyUtils::IcalendarUtils.to_ical_datetime(entity.arrival)
        event.dtend    = EasyUtils::IcalendarUtils.to_ical_datetime(entity.departure)

        calendar = Icalendar::Calendar.new
        calendar.add_event(event)
        calendar.to_ical
      end

      # HTTP PUT request
      #
      # Only update attendance
      #
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new attendance
        if force_create || !exist?
          log_error('Create a new attendance is not supported')
          raise Forbidden
        end

        request.body.rewind
        icalendar = Icalendar::Calendar.parse(request.body.read).first
        ievent = icalendar.events.first

        # `next_action` must be String because of somebody thought that
        # this value will be set only via params and not as Time
        attributes = {
          'arrival' => ievent.dtstart.value,
          'departure' => ievent.dtend.value
        }

        # Save attendance
        @entity.safe_attributes = attributes

        # Save attendance and return `[saved, new_record]`
        if @entity.save
          return true, false
        else
          return false, false
        end
      end

      private

        def find_entity
          uid = path.split('/').last
          uid.sub!(/\.ics\Z/, '')

          EasyAttendancesResource.scope.where(id: uid).first
        end

    end
  end
end
