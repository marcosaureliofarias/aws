module EasyCalendar
  module Caldav
    class VersionResource < EntityResource

      def getetag
        %{"#{entity.id}-#{entity.updated_on.to_i}"}
      end

      def displayname
        entity.name
      end

      def getlastmodified
        entity.updated_on.httpdate
      end

      def creationdate
        entity.created_on.iso8601
      end

      def url
        Rails.application.routes.url_helpers.url_for(
          controller: 'versions',
          action:     'show',
          id:         entity.id,
          only_path:  false,
          host: Mailer.default_url_options[:host],
          port: Mailer.default_url_options[:port]
        )
      end

      def _calendar_data
        event = Icalendar::Event.new
        event.uid          = entity.id.to_s
        event.url          = url
        event.location     = url
        event.summary      = entity.name
        event.description  = entity.description.to_s
        event.dtstart      = EasyUtils::IcalendarUtils.to_ical_date(entity.effective_date)
        event.dtend        = EasyUtils::IcalendarUtils.to_ical_date(entity.effective_date + 1.day)
        event.ip_class     = 'PUBLIC'

        calendar = Icalendar::Calendar.new
        calendar.add_event(event)
        calendar.to_ical
      end

      # HTTP PUT request
      #
      # Only update version
      #
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new version
        if force_create || !exist?
          log_error('Create a new version is not supported')
          raise Forbidden
        end

        request.body.rewind
        icalendar = Icalendar::Calendar.parse(request.body.read).first
        ievent = icalendar.events.first

        # End is shifted on all day event
        attributes = {
          'name' => ievent.summary.to_s.force_encoding(Encoding::UTF_8),
          'effective_date' => ievent.dtstart
        }

        # Save version
        @entity.safe_attributes = attributes

        # Save version and return `[saved, new_record]`
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

          VersionsResource.scope.where(id: uid).first
        end

    end
  end
end
