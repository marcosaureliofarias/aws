module EasyCalendar
  module Caldav
    class EasyCrmCaseContractsResource < Resource

      def self.scope
        EasyCrmCase.where(assigned_to_id: User.current.id).
                    where.not(contract_date: nil)
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
        I18n.t(:label_contracts)
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
        '#a7c56b'
      end

      def calendar_order
        '4'
      end

      def children
        report_query
      end

      # HTTP REPORT request.
      #
      # Query on crm cases
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

        c_table = EasyCrmCase.table_name

        scope = EasyCrmCaseContractsResource.scope

        if start_date
          scope = scope.where("#{c_table}.contract_date >= ?", start_date)
        end

        if end_date
          scope = scope.where("#{c_table}.contract_date <= ?", end_date)
        end

        scope.uniq.map do |event|
          EasyCrmCaseContractResource.new(path + '/' + event.id.to_s + '.ics', controller, event)
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

        events = EasyCrmCaseContractsResource.scope.where(id: data).map{|i| [i.id.to_s, i] }.to_h

        data.map do |uid|
          event = events[uid]
          event_path = path + '/' + uid + '.ics'

          if event
            EasyCrmCaseContractResource.new(event_path, controller, event)
          else
            EasyExtensions::Webdav::StatusResource.new(event_path, NotFound)
          end
        end
      end

      private

        def last_updated
          EasyCrmCaseContractsResource.scope.order(updated_at: :desc).first
        end

    end
  end
end
