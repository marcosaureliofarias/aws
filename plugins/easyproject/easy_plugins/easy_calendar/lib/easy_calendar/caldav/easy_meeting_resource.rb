require 'icalendar/tzinfo'

module EasyCalendar
  module Caldav
    class EasyMeetingResource < EntityResource
      include EasyExtensions::Webdav::Logger

      def allowed_methods
        (super + ['DELETE']).freeze
      end

      def getetag
        %{"#{entity.etag}"}
      end

      def displayname
        entity.name
      end

      def getlastmodified
        entity.updated_at.httpdate
      end

      def creationdate
        entity.created_at.iso8601
      end

      def url
        Rails.application.routes.url_helpers.easy_meeting_url(entity, Mailer.default_url_options).to_s
      end

      def _calendar_data
        tzinfo = TZInfo::Timezone.get(User.current.time_zone && User.current.time_zone.tzinfo.identifier || 'UTC')
        timezone = tzinfo.ical_timezone(entity.start_time)

        event = Icalendar::Event.new
        event.uid      = entity.uid
        event.url      = url
        event.summary  = entity.name
        event.location = entity.location

        if entity.all_day?
          event.dtstart = EasyUtils::IcalendarUtils.to_ical_date(entity.start_time)
          event.dtend   = EasyUtils::IcalendarUtils.to_ical_date(entity.end_time + 1.day)
        else
          event.dtstart = EasyUtils::IcalendarUtils.to_ical_datetime(entity.start_time)
          event.dtend   = EasyUtils::IcalendarUtils.to_ical_datetime(entity.end_time)
        end

        if entity.author
          event.organizer = "MAILTO:#{entity.author.mail}"
        end

        event.attendee = entity.external_mails.map{|u| "MAILTO:#{u}" }
        event.priority = to_ical_priority(entity.priority)
        event.ip_class = to_ical_privacy(entity.privacy)

        description = entity.description.to_s
        if !description.include?(url)
          description = url + "\r\n\r\n" + description
        end
        event.description = description

        if @entity.easy_is_repeating? && @entity.big_recurring?
          rrule = EasyUtils::IcalendarUtils.repeating_to_ical(@entity.easy_repeat_settings)
          recur = Icalendar::Values::Recur.new(nil)
          recur.__setobj__(rrule)

          event.rrule = recur
        end

        if (my_invitation = entity.invitation_for(User.current))
          alarms = Icalendar::Alarm.parse(my_invitation.alarms.join)
          alarms.each do |alarm|
            event.add_alarm(alarm)
          end
        else
          event.alarm do |a|
            a.action  = 'DISPLAY'
            a.summary = '5 minutes before'
            a.trigger = '-PT05M'
          end
          event.alarm do |a|
            a.action  = 'DISPLAY'
            a.summary = '30 minutes before'
            a.trigger = '-PT30M'
          end
        end

        entity.easy_invitations.each do |inv|
          stat = inv.accepted? ? 'ACCEPTED' : 'DECLINED' unless inv.accepted.nil?
          prop = {'PARTSTAT' => stat, 'CN' => inv.user.name}

          if inv.user_id == entity.author_id
            next
          end

          attendee = Icalendar::Values::CalAddress.new("MAILTO:#{inv.user.mail}", prop)
          event.append_attendee(attendee)
        end

        calendar = Icalendar::Calendar.new
        calendar.add_timezone(timezone)
        calendar.add_event(event)
        calendar.to_ical
      end

      # HTTP PUT request
      #
      # Creat an event on calendar
      # Only one resource should be created
      #
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new address resource
        if force_create && exist?
          log_error('Create a new resource is not supported')
          raise Conflict
        end

        request.body.rewind
        icalendar = Icalendar::Calendar.parse(request.body.read).first
        ievent = icalendar.events.first

        # See https://tools.ietf.org/html/rfc6638#section-3.2.2.1
        # 3.2.2.1.  Allowed "Attendee" Changes
        #
        # User is attempting to create a new event which is organized
        # by somebody else.
        #
        # It could happens if the event from one application is transfered
        # by "accepting" to another one.
        #
        # In that case see https://tools.ietf.org/html/rfc6638#section-3.2.4.4
        # 3.2.4.4.  CALDAV:allowed-attendee-scheduling-object-change Precondition
        #
        if !exist? &&
             ievent.organizer &&
             ievent.organizer.value.is_a?(URI::MailTo) &&
             !User.current.mails.include?(ievent.organizer.value.to)

          log_error('The email of the event organizer does not match any of the emails of the user')
          raise Forbidden
        end

        if (new_record = !exist?)
          @entity = EasyMeeting.new
          @entity.uid = ievent.uid
          @entity.author = User.current
        end

        # Should not happend
        # Just for sure
        if @entity.big_recurring_children? && @entity.easy_repeat_parent
          @entity = @entity.easy_repeat_parent
        end

        attributes = {
          'name' => ievent.summary.to_s.force_encoding(Encoding::UTF_8),
          'description' => ievent.description.to_s.force_encoding(Encoding::UTF_8),
          'start_time' => ievent.dtstart.value,
          'end_time' => EasyUtils::IcalendarUtils.get_end(ievent.dtstart, ievent.dtend, ievent.duration),
          'priority' => from_ical_priority(ievent.priority),
          'privacy' => from_ical_privacy(ievent.ip_class),
        }

        rrule = ievent.rrule.first
        if rrule
          attributes['big_recurring'] = true
          attributes['easy_is_repeating'] = true
          attributes['easy_repeat_settings'] = EasyUtils::IcalendarUtils.repeating_from_ical(rrule)
        end

        # All day event is just a Date
        if ievent.dtstart.is_a?(Icalendar::Values::Date) || ievent.dtend.is_a?(Icalendar::Values::Date)
          attributes['all_day'] = true

          # End is shifted on all day event
          attributes['end_time'] -= 1.day
        else
          attributes['all_day'] = false
        end

        # Save room or location
        if ievent.location.present?
          location = ievent.location.value.to_s.force_encoding(Encoding::UTF_8).gsub("\n", ', ')
          if (room = EasyRoom.find_by(name: location.split(", ").first))
            attributes['easy_room_id'] = room.id
          else
            attributes['place_name'] = location
          end
        end

        # Parse attendee
        attendees = ievent.attendee.map do |attendee|
          value = attendee.value

          if value.is_a?(URI) && attendee.value.opaque
            [attendee.value.opaque, attendee.ical_params]
          elsif value.is_a?(String) && value.start_with?('mailto:')
            [value.sub(/\Amailto:/, ''), attendee.ical_params]
          end
        end
        attendees.compact!
        attendees = attendees.to_h

        # Attendee is saved as User if email is registered
        # or emails is used for mails field
        emails = attendees.map{|email, _| email.downcase }.uniq
        if emails.any?
          email_addresses = EmailAddress.where("LOWER(address) IN (?)", emails).pluck('user_id', Arel.sql('LOWER(address)'))

          attributes['user_ids'] = email_addresses.map(&:first).uniq
          attributes['mails'] = (emails - email_addresses.map(&:second)).join(', ')

          # Check if client already sent scheduling message or
          # client want no scheduling. To make it easier client
          # should sent all or none notifications.
          not_send_invitations = attendees.any? do |_, ical_params|
            # Be careful, `ical_params` is delegated Hash
            next if !ical_params.is_a?(Icalendar::DowncasedHash)
            next if !ical_params['schedule-agent'].is_a?(Array)

            ical_params['schedule-agent'].include?('CLIENT') ||
            ical_params['schedule-agent'].include?('NONE')
          end

          # Notification is managed by the caldav client
          @entity.emailed = true
          @entity.do_not_send_notifications = not_send_invitations
        end

        # Save meeting
        @entity.safe_attributes = attributes

        # Ensure author
        if !@entity.user_ids.include?(@entity.author_id)
          @entity.user_ids += [@entity.author_id]
        end

        # Prevent for calling calback
        if @entity.changed? && !@entity.save
          log_error("Entity cannot be saved: #{errors_full_messages}")
          return false, new_record
        end

        # Changing invitations
        # - accept/decline
        # - changing alarms
        if !new_record && (my_invitation = @entity.invitation_for(User.current))
          ievent.alarms.each do |alarm|
            alarm.description = alarm.description.to_s.force_encoding(Encoding::UTF_8)
          end

          my_invitation.alarms = ievent.alarms.map(&:to_ical)
          my_invitation.skip_notifications = true
          my_invitation.save

          attendee = attendees.values_at(*User.current.mails).first
          if !new_record && attendee
            status = attendee['partstat'].try(:first)
            accepted = case status.to_s.upcase
                       when 'ACCEPTED'
                         true
                       when 'DECLINED'
                         false
                       else
                         # NEEDS-ACTION, TENTATIVE, DELEGATED
                         nil
                       end

            begin
              @entity.accept_or_decline!(User.current, accepted)
            rescue => e
              # For unknow reason this sometimes raise a deadlock on DB
              log_error "Changing invitations_ #{e.message}"
            end
          end

        end

        return true, new_record
      end

      # HTTP DELETE request
      #
      # Delete event or reject invitation
      #
      def delete
        entity

        if entity.author == User.current
          # Delete event
          if entity.big_recurring?
            entity.destroy_all_repeated
          else
            entity.destroy
          end
        else
          # Reject invitation
          entity.decline!(User.current)
        end
      end

      private

        def find_entity
          uid = path.split('/').last
          uid.sub!(/\.ics\Z/, '')

          meeting = User.current.invited_to_meetings.find_by(uid: uid)

          if meeting.nil?
            nil
          elsif meeting.big_recurring_children? && meeting.easy_repeat_parent
            meeting.easy_repeat_parent
          else
            meeting
          end
        end

        # Based on CUA iCalendar priority property which have three-level scheme
        # RFC 2445 - 4.8.1.9 Priority
        def to_ical_priority(value)
          case value
          when 'high'
            1
          when 'low'
            9
          else
            5
          end
        end

        # RFC 2445 - 4.8.1.3 Classification
        def to_ical_privacy(value)
          case value
          when 'xprivate'
           'PRIVATE'
          when 'confidential'
           'CONFIDENTIAL'
          else
           'PUBLIC'
          end
        end

        # Based on CUA iCalendar priority property which have three-level scheme
        # RFC 2445 - 4.8.1.9 Priority
        def from_ical_priority(value)
          case value
          when 1..4
            'high'
          when 6..9
            'low'
          else
            'normal'
          end
        end

        # RFC 2445 - 4.8.1.3 Classification
        def from_ical_privacy(value)
          case value.to_s.upcase
          when 'PRIVATE'
            'xprivate'
          when 'CONFIDENTIAL'
            'confidential'
          else
            # PUBLIC (default)
            'xpublic'
          end
        end

    end
  end
end
