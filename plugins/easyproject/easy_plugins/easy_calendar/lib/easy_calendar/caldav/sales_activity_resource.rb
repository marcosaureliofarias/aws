module EasyCalendar
  module Caldav
    ##
    # Sales activities (EasyEntityActivity) for EasyCrmCase and EasyContact
    #
    class SalesActivityResource
      include WEBrick::HTTPStatus

      def self.by_path(path)
        if path =~ /\/(\d+).ics\Z/
          entity_type = EasyEntityActivity.where(id: $1).limit(1).pluck(:entity_type).first
          by_entity_type(entity_type)
        else
          raise NotFound
        end
      end

      def self.by_entity(entity)
        by_entity_type(entity.entity_type)
      end

      def self.by_entity_type(entity_type)
        case entity_type
        when 'EasyContact'; SalesActivityResource::EasyContact
        when 'EasyCrmCase'; SalesActivityResource::EasyCrmCase
        else
          raise NotFound
        end
      end


      # Easy contact
      # =======================================================================

      class Base < EntityResource

        attr_reader :activity_entity

        ACTIVITY_DURATION = 15.minutes

        def activity_entity
          @activity_entity ||= @entity && @entity.entity
        end

        def getetag
          %{"#{entity.id}-#{entity.updated_at.to_i}"}
        end

        def displayname
          activity_entity.name
        end

        def getlastmodified
          entity.updated_at.httpdate
        end

        def creationdate
          entity.created_at.iso8601
        end

        def _calendar_data
          event = Icalendar::Event.new
          event.uid      = entity.id.to_s
          event.url      = url
          event.location = url
          event.summary  = "#{entity.category.try(:name)} - #{activity_entity.name}"
          event.ip_class = 'PUBLIC'

          if entity.all_day?
            event.dtstart = EasyUtils::IcalendarUtils.to_ical_date(entity.start_time)
            event.dtend   = EasyUtils::IcalendarUtils.to_ical_date(entity.start_time + 1.day)
          else
            event.dtstart = EasyUtils::IcalendarUtils.to_ical_datetime(entity.start_time)

            if entity.end_time
              end_time = entity.end_time
            else
              end_time = entity.start_time + ACTIVITY_DURATION
            end

            event.dtend = EasyUtils::IcalendarUtils.to_ical_datetime(end_time)
          end

          event.description = calendar_description
          append_x_alt_desc(event, x_alt_desc)

          entity.easy_entity_activity_attendees.each do |attendee|
            attendee = attendee.entity
            case attendee
            when Principal
              email = attendee.mail
              name = attendee.name
            when EasyContact
              email = attendee.cf_email_value
              name = attendee.name
            end

            next unless email

            prop = {'CN' => name}
            attendee = Icalendar::Values::CalAddress.new("MAILTO:#{email}", prop)
            event.append_attendee(attendee)
          end

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
            'start_time' => ievent.dtstart.value,
            'end_time' => ievent.dtend.value
          }

          # All day event is just a Date
          if ievent.dtstart.is_a?(Icalendar::Values::Date) || ievent.dtend.is_a?(Icalendar::Values::Date)
            attributes['all_day'] = true
          else
            attributes['all_day'] = false
          end

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

            SalesActivitiesResource.scope.where(id: uid).first
          end

      end


      # Easy crm case
      # =======================================================================

      class EasyCrmCase < Base

        def url
          Rails.application.routes.url_helpers.url_for(
            controller: 'easy_crm_cases',
            action:     'show',
            id:         activity_entity.id,
            only_path:  false,
            host: Mailer.default_url_options[:host],
            port: Mailer.default_url_options[:port]
          )
        end

        def calendar_description
          desc = %{#{activity_entity} (#{url})\n\n}

          activity_entity.easy_contacts.each do |contact|
            desc << %{#{contact}\n}
            desc << %{#{l('custom_field_names.easy_contacts_email.label')}: #{contact.cf_email_value}\n}
            desc << %{#{l('custom_field_names.easy_contacts_telephone.label')}: #{contact.cf_telephone_value}\n\n}
          end

          desc << %{#{l(:field_category)}: #{entity.category}\n}
          desc << %{#{l(:field_easy_entity_activity_start_time)}: #{format_time(entity.start_time)}\n}
          desc << %{#{l(:field_description)}:\n #{to_text(entity.description)}\n\n}

          notes = activity_entity.journals.visible.with_notes.pluck(:notes)
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
            <a href="#{url}">#{activity_entity}</a>
            <br>
          }

          activity_entity.easy_contacts.each do |contact|
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
              <strong>#{l(:field_category)}:</strong>
              #{entity.category}
            </p>

            <p>
              <strong>#{l(:field_easy_entity_activity_start_time)}:</strong>
              #{format_time(entity.start_time)}
            </p>

            <p>
              <br>
              <strong>#{l(:field_description)}:</strong>
              #{entity.description}
              <br>
            </p>
          }

          notes = activity_entity.journals.visible.with_notes.pluck(:notes)
          if notes.any?
            desc << %{<br><strong>#{l(:field_notes)}:</strong><br>}
            notes.each do |note|
              desc << note
              desc << %{<br><br>}
            end
          end

          desc
        end

      end


      # Easy contact
      # =======================================================================

      class EasyContact < Base

        def url
          Rails.application.routes.url_helpers.url_for(
            controller: 'easy_contacts',
            action:     'show',
            id:         activity_entity.id,
            only_path:  false,
            host: Mailer.default_url_options[:host]
          )
        end

        def calendar_description
          desc = %{#{activity_entity} (#{url})\n\n}

          desc << %{#{l(:field_category)}: #{entity.category}\n}
          desc << %{#{l(:field_easy_entity_activity_start_time)}: #{format_time(entity.start_time)}\n}
          desc << %{#{l(:field_description)}:\n #{to_text(entity.description)}\n\n}

          notes = activity_entity.journals.visible.with_notes.pluck(:notes)
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
            <a href="#{url}">#{activity_entity}</a>
            <br>
          }

          desc << %{
            <p>
              <strong>#{l(:field_category)}:</strong>
              #{entity.category}
            </p>

            <p>
              <strong>#{l(:field_easy_entity_activity_start_time)}:</strong>
              #{format_time(entity.start_time)}
            </p>

            <p>
              <br>
              <strong>#{l(:field_description)}:</strong>
              #{entity.description}
              <br>
            </p>
          }

          notes = activity_entity.journals.visible.with_notes.pluck(:notes)
          if notes.any?
            desc << %{<br><strong>#{l(:field_notes)}:</strong><br>}
            notes.each do |note|
              desc << note
              desc << %{<br><br>}
            end
          end

          desc
        end

      end

    end
  end
end
