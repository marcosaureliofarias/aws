module EasyCalendar
  module Caldav
    class IssueResource < EntityResource

      def getetag
        %{"#{entity.id}-#{entity.updated_on.to_i}"}
      end

      def displayname
        entity.subject
      end

      def getlastmodified
        entity.updated_on.httpdate
      end

      def creationdate
        entity.created_on.iso8601
      end

      def url
        Rails.application.routes.url_helpers.url_for(
          controller: 'issues',
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
        event.summary  = entity.subject
        event.dtstart  = EasyUtils::IcalendarUtils.to_ical_date(entity.start_date)
        event.dtend    = EasyUtils::IcalendarUtils.to_ical_date(entity.due_date + 1.day)
        event.ip_class = 'PUBLIC'

        event.description = calendar_description
        append_x_alt_desc(event, x_alt_desc)

        calendar = Icalendar::Calendar.new
        calendar.add_event(event)
        calendar.to_ical
      end

      def calendar_description
        notes = entity.journals.visible.with_notes.pluck(:notes)

        desc  = %{#{entity} (#{url})\n\n}
        desc << %{#{l(:field_start_date)}: #{format_date(entity.start_date)}\n}
        desc << %{#{l(:field_due_date)}: #{format_date(entity.due_date)}\n}
        desc << %{#{l(:field_priority)}: #{entity.priority}\n}
        desc << %{#{l(:field_tracker)}: #{entity.tracker}\n}
        desc << %{#{l(:field_project)}: #{entity.project}\n}
        desc << %{#{l(:field_author)}: #{entity.author}\n}
        desc << %{#{l(:field_done_ratio)}: #{entity.done_ratio}\n\n}
        desc << %{#{l(:field_description)}:\n #{to_text(entity.description)}\n\n}

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
            <strong>#{l(:field_start_date)}:</strong>
            #{format_date(entity.start_date)}
          </p>

          <p>
            <strong>#{l(:field_due_date)}:</strong>
            #{format_date(entity.due_date)}
          </p>

          <p>
            <strong>#{l(:field_priority)}:</strong>
            #{entity.priority}
          </p>

          <p>
            <strong>#{l(:field_tracker)}:</strong>
            #{entity.tracker}
          </p>

          <p>
            <strong>#{l(:field_project)}:</strong>
            #{entity.project}
          </p>

          <p>
            <strong>#{l(:field_author)}:</strong>
            #{entity.author}
          </p>

          <p>
            <strong>#{l(:field_done_ratio)}:</strong>
            #{entity.done_ratio}
          </p>

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
      # Only update issue
      #
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new issue
        if force_create || !exist?
          log_error('Create a new issue is not supported')
          raise Forbidden 
        end

        request.body.rewind
        icalendar = Icalendar::Calendar.parse(request.body.read).first
        ievent = icalendar.events.first

        # End is shifted on all day event
        attributes = {
          'subject' => ievent.summary.to_s.force_encoding(Encoding::UTF_8),
          # 'description' => ievent.description.to_s.force_encoding(Encoding::UTF_8),
          'start_date' => ievent.dtstart,
          'due_date' => (ievent.dtend - 1.day)
        }

        # Save issue
        @entity.safe_attributes = attributes

        # Save issue and return `[saved, new_record]`
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

          IssuesResource.scope.where(id: uid).first
        rescue RangeError
          # Mac ignore permission about creating tasks and could send id like
          # "040000008200E00074C5B7101A82E0080000000050D8AFEEF71BD301000000000000000010000000C777B19787EACA4BA0F0B3E618F7DA25"
        end

    end
  end
end
