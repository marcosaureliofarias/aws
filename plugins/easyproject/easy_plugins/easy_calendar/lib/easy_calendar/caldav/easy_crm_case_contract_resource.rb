module EasyCalendar
  module Caldav
    class EasyCrmCaseContractResource < EasyCrmCaseResource

      def getetag
        %{"#{entity.id}-#{entity.updated_at.to_i}"}
      end

      def displayname
        entity.name
      end

      def getlastmodified
        entity.updated_at.httpdate
      end

      def creationdate
        entity.created_on.iso8601
      end

      def url
        Rails.application.routes.url_helpers.url_for(
          controller: 'easy_crm_cases',
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
        event.summary  = entity.name
        event.ip_class = 'PUBLIC'
        event.dtstart  = EasyUtils::IcalendarUtils.to_ical_date(entity.contract_date)
        event.dtend    = EasyUtils::IcalendarUtils.to_ical_date(entity.contract_date + 1.day)

        # See ancestor class
        event.description = calendar_description
        append_x_alt_desc(event, x_alt_desc)

        calendar = Icalendar::Calendar.new
        calendar.add_event(event)
        calendar.to_ical
      end

      # HTTP PUT request
      #
      # Only update crm case
      #
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new crm case
        if force_create || !exist?
          log_error('Create a new CRM case is not supported')
          raise Forbidden 
        end

        request.body.rewind
        icalendar = Icalendar::Calendar.parse(request.body.read).first
        ievent = icalendar.events.first

        # `contract_date` must be String because of somebody thought that
        # this value will be set only via params and not as Time
        attributes = {
          'name' => ievent.summary.to_s.force_encoding(Encoding::UTF_8),
          'contract_date' => ievent.dtstart.to_s
        }

        # Save crm case
        @entity.safe_attributes = attributes

        # Save crm case and return `[saved, new_record]`
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

          EasyCrmCaseContractsResource.scope.where(id: uid).first
        end

    end
  end
end
