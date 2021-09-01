module EasyCalendar
  module Caldav
    class EasyCrmCaseResource < EntityResource

      EASY_CRM_CASE_DURATION = 15.minutes

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
        event.url      = url
        event.location = url
        event.summary  = entity.name
        event.ip_class = 'PUBLIC'

        if entity.all_day?
          event.dtstart = EasyUtils::IcalendarUtils.to_ical_date(entity.next_action)
          event.dtend   = EasyUtils::IcalendarUtils.to_ical_date(entity.next_action + 1.day)
        else
          event.dtstart = EasyUtils::IcalendarUtils.to_ical_datetime(entity.next_action)
          event.dtend   = EasyUtils::IcalendarUtils.to_ical_datetime(entity.next_action + EASY_CRM_CASE_DURATION)
        end

        event.description = calendar_description
        append_x_alt_desc(event, x_alt_desc)

        calendar = Icalendar::Calendar.new
        calendar.add_event(event)
        calendar.to_ical
      end

      def calendar_description
        desc  = %{#{entity} (#{url})\n\n}
        desc << %{#{l(:field_easy_crm_case_contract_date)}: #{entity.contract_date}\n}
        desc << %{#{l(:field_easy_crm_case_next_action)}: #{entity.next_action}\n}
        desc << %{#{l(:field_status)}: #{entity.easy_crm_case_status}\n}
        desc << %{#{l(:field_price)}: #{entity.price} #{entity.currency}\n\n}

        entity.easy_contacts.each do |contact|
          desc << %{#{contact}\n}
          desc << %{#{l('custom_field_names.easy_contacts_email.label')}: #{contact.cf_email_value}\n}
          desc << %{#{l('custom_field_names.easy_contacts_telephone.label')}: #{contact.cf_telephone_value}\n\n}
        end

        desc << %{#{l(:field_description)}:\n #{to_text(entity.description)}\n\n}

        notes = entity.journals.visible.with_notes.pluck(:notes)
        if notes.any?
          desc << %{#{l(:field_notes)}:\n}
          notes.each do |note|
            desc << %{#{to_text(note)}\n\n}
          end
        end

        desc
      end

      def x_alt_desc
        desc = %{
          <a href="#{url}">#{entity}</a>
          <br>

          <p>
            <strong>#{l(:field_easy_crm_case_contract_date)}:</strong>
            #{format_date(entity.contract_date)}
          </p>

          <p>
            <strong>#{l(:field_easy_crm_case_next_action)}:</strong>
            #{format_time(entity.next_action)}
          </p>

          <p>
            <strong>#{l(:field_status)}:</strong>
            #{entity.easy_crm_case_status}
          </p>

          <p>
            <strong>#{l(:field_price)}:</strong>
            #{entity.price} #{entity.currency}
          </p>
          }

        entity.easy_contacts.each do |contact|
          desc << %{
            <p>
              <br>
              #{contact}
              <br>
              #{l('custom_field_names.easy_contacts_email.label')}: #{contact.cf_email_value}<br>
              #{l('custom_field_names.easy_contacts_telephone.label')}: #{contact.cf_telephone_value}<br>
            </p>
          }
        end

        desc << %{
          <p>
            <br>
            <strong>#{l(:field_description)}:</strong>
            #{entity.description}
            <br>
          </p>
        }

        notes = entity.journals.visible.with_notes.pluck(:notes)
        if notes.any?
          desc << %{<br><strong>#{l(:field_notes)}:</strong><br>}
          notes.each do |note|
            desc << note
            desc << %{<br><br>}
          end
        end

        desc
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

        # `next_action` must be String because of somebody thought that
        # this value will be set only via params and not as Time
        # Attribute `all_day` must be set before `next_action`
        attributes = {
          'name' => ievent.summary.to_s.force_encoding(Encoding::UTF_8),
          'all_day' => (ievent.dtstart.is_a?(Icalendar::Values::Date) ||
                        ievent.dtend.is_a?(Icalendar::Values::Date)),
          'next_action' => ievent.dtstart.to_s
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

          EasyCrmCasesResource.scope.where(id: uid).first
        end

    end
  end
end
