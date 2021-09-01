module EasyCalendar
  module Caldav
    class EasyMeetingsResource < Resource

      def collection?
        true
      end

      def controlled_access?
        true
      end

      def readable?
        true
      end

      def writeable?
        true
      end

      def property_names
        ['resourcetype', 'displayname', 'getctag', 'supported-report-set', 'supported-calendar-component-set', 'calendar-color', 'calendar-order', 'max-instances'].freeze
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND', 'REPORT'].freeze
      end

      def resourcetype
        render_xml_element do |xml|
          xml['d'].collection
          xml['c'].calendar
        end
      end

      def displayname
        I18n.t(:label_meetings)
      end

      def getctag
        value = last_updated && last_updated.updated_at
        "\"#{value.to_i}\""
      end

      # This property should be protected but it isn't
      # https://tools.ietf.org/html/rfc4791#section-5.2.8
      def max_instances
        EasyMeeting::MAX_BIG_RECURRING_COUNT
      end

      def supported_report_set
        render_xml_element do |xml|
          xml['d'].send('supported-report') do
            xml['d'].send('report') do
              xml['c'].send('calendar-query')
            end
          end

          xml['d'].send('supported-report') do
            xml['d'].send('report') do
              xml['c'].send('calendar-multiget')
            end
          end
        end
      end

      def supported_calendar_component_set
        render_xml_element do |xml|
          xml['c'].comp(name: 'VEVENT')
        end
      end

      def calendar_color
        '#daddf6'
      end

      def calendar_order
        '0'
      end

      def children
        report_query
      end

      # HTTP REPORT request.
      #
      # Query on meeting calendar
      #
      def report_query(time_range=nil, **options)
        time_range ||= {}

        meetings = EasyMeeting.arel_table
        user = User.current

        scope = user.invited_to_meetings.preload(easy_invitations: {user: :email_address})
        scope = scope.where(easy_invitations: {accepted: [nil, true]})
        scope = scope.select('easy_meetings.*, easy_invitations.accepted AS accepted')

        if start_date = time_range['start']
          scope = scope.where(meetings[:start_time].gt(start_date))
        end

        if end_date = time_range['end']
          scope = scope.where(meetings[:end_time].lt(end_date))
        end

        events = scope.distinct.to_a

        # Delete big recurring events and get original parent ids
        repeated_parent_meeting_ids = Set.new
        events.delete_if do |event|
          if event.big_recurring_children?
            repeated_parent_meeting_ids << event.easy_repeat_parent_id
            true
          else
            false
          end
        end

        # Add original recurring events
        # Others will be add as RRULE
        events.concat(EasyMeeting.where(id: repeated_parent_meeting_ids.to_a, big_recurring: true))

        # In range could be recurring parent twice
        events.uniq!

        events.map do |event|
          EasyMeetingResource.new(path + '/' + event.uid + '.ics', controller, event)
        end
      end

      # HTTP REPORT request.
      #
      # Multiget events
      #
      def report_multiget(data, **options)
        # Get uids from href element
        data.map! do |href|
          uid = href.split('/').last
          uid.sub!(/\.ics\Z/, '')
          uid
        end

        # Visible events (group is there becase webdav have to render 404
        # if resource is not found)
        events = User.current.invited_to_meetings.where(uid: data).group_by(&:uid)

        # Contact or not not found
        data.map do |uid|
          event = events[uid].try(:first)

          event_path = path + '/' + uid + '.ics'

          if event
            EasyMeetingResource.new(event_path, controller, event)
          else
            EasyExtensions::Webdav::StatusResource.new(event_path, NotFound)
          end
        end

      end

      private

        def last_updated
          User.current.invited_to_meetings.order(updated_at: :desc).first
        end

    end
  end
end
