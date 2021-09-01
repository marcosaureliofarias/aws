module EasyCalendar
  module Caldav
    class EasyAttendancesResource < Resource

      def self.scope
        EasyAttendance.includes(:easy_attendance_activity).
                       where(user_id: User.current.id,
                             easy_attendance_activities: { at_work: false }).
                       where.not(arrival: nil, departure: nil)
      end

      def collection?
        true
      end

      def controlled_access?
        true
      end

      def readable?
        true
      end

      def creatable?
        false
      end

      def updatable?
        true
      end

      def property_names
        ['resourcetype', 'displayname', 'getctag', 'supported-report-set', 'supported-calendar-component-set', 'calendar-color', 'calendar-order'].freeze
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
        I18n.t('easy_attendance.label')
      end

      def getctag
        value = last_updated && last_updated.updated_at
        %{"#{value.to_i}"}
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
        '#F7A4A4'
      end

      def calendar_order
        '6'
      end

      def children
        report_query
      end

      # HTTP REPORT request.
      #
      # Query on attendances
      #
      #
      #          |-------| (range)
      #    ====
      #        ====
      #            ====
      #                ====
      #                    ====
      #
      def report_query(time_range=nil, **options)
        time_range ||= {}
        start_date = time_range['start']
        end_date = time_range['end']

        a_table = EasyAttendance.table_name

        scope = EasyAttendancesResource.scope

        if start_date && end_date
          scope = scope.where("(#{a_table}.arrival >= :from AND #{a_table}.arrival <= :to) OR" +
                              "(#{a_table}.departure >= :from AND #{a_table}.departure <= :to)",
                              from: start_date, to: end_date)
        elsif start_date
          scope = scope.where("#{a_table}.departure >= :from", from: start_date)
        elsif end_date
          scope = scope.where("#{a_table}.arrival <= :to", to: end_date)
        end

        scope.uniq.map do |event|
          EasyAttendanceResource.new(path + '/' + event.id.to_s + '.ics', controller, event)
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

        events = EasyAttendancesResource.scope.where(id: data).map{|i| [i.id.to_s, i] }.to_h

        data.map do |uid|
          event = events[uid]
          event_path = path + '/' + uid + '.ics'

          if event
            EasyAttendanceResource.new(event_path, controller, event)
          else
            EasyExtensions::Webdav::StatusResource.new(event_path, NotFound)
          end
        end
      end

      private

        def last_updated
          EasyAttendancesResource.scope.order(updated_at: :desc).first
        end

    end
  end
end
