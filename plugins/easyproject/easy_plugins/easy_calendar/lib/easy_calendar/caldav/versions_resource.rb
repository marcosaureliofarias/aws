module EasyCalendar
  module Caldav
    class VersionsResource < Resource

      def self.scope
        Version.visible.open.where.not(effective_date: nil)
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
        I18n.t(:label_version_plural)
      end

      def getctag
        value = last_updated && last_updated.updated_on
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
        '#f5f5f5'
      end

      def calendar_order
        '2'
      end

      def children
        report_query
      end

      # HTTP REPORT request.
      #
      # Query on vesions
      #
      def report_query(time_range=nil, **options)
        time_range ||= {}
        start_date = time_range['start']
        end_date = time_range['end']

        v_table = Version.table_name

        scope = VersionsResource.scope

        if start_date
          scope = scope.where("#{v_table}.effective_date >= ?", start_date)
        end

        if end_date
          scope = scope.where("#{v_table}.effective_date <= ?", end_date)
        end

        scope.uniq.map do |event|
          VersionResource.new(path + '/' + event.id.to_s + '.ics', controller, event)
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

        events = VersionsResource.scope.where(id: data).map{|v| [v.id.to_s, v] }.to_h

        data.map do |uid|
          event = events[uid]
          event_path = path + '/' + uid + '.ics'

          if event
            VersionResource.new(event_path, controller, event)
          else
            EasyExtensions::Webdav::StatusResource.new(event_path, NotFound)
          end
        end
      end

      private

        def last_updated
          VersionsResource.scope.order(updated_on: :desc).first
        end

    end
  end
end
