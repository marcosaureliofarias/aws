module EasyCalendar
  module Caldav
    class SalesActivitiesResource < Resource

      def self.scope
        EasyEntityActivity.includes(:easy_entity_activity_attendees).
                           preload(:entity).
                           where(entity_type: ['EasyCrmCase', 'EasyContact'],
                                 is_finished: false,
                                 easy_entity_activity_attendees: { entity_id: User.current.id,
                                                                   entity_type: 'Principal' }).
                           where.not(start_time: nil)
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
        I18n.t(:label_sales_activities)
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
        '#f96d56'
      end

      def calendar_order
        '5'
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
        props = options.fetch(:props, [])

        e_table = EasyEntityActivity.table_name

        scope = SalesActivitiesResource.scope
        scope = preloads_by_props(scope, props)

        if start_date
          scope = scope.where("#{e_table}.start_time >= ?", start_date)
        end

        if end_date
          scope = scope.where("#{e_table}.start_time <= ?", end_date)
        end

        scope.uniq.map do |event|
          klass = SalesActivityResource.by_entity(event)
          klass.new(path + '/' + event.id.to_s + '.ics', controller, event)
        end
      end

      # HTTP REPORT request.
      #
      # Multiget events
      #
      def report_multiget(data, **options)
        props = options.fetch(:props, [])

        # Get uids from href element
        data.map! do |href|
          uid = href.split('/').last
          uid.sub!(/\.ics\Z/, '')
          uid
        end

        scope = SalesActivitiesResource.scope
        scope = preloads_by_props(scope, props)

        events = scope.where(id: data).map{|v| [v.id.to_s, v] }.to_h

        data.map do |uid|
          event = events[uid]
          event_path = path + '/' + uid + '.ics'

          if event
            klass = SalesActivityResource.by_entity(event)
            klass.new(event_path, controller, event)
          else
            EasyExtensions::Webdav::StatusResource.new(event_path, NotFound)
          end
        end
      end

      private

        def last_updated
          SalesActivitiesResource.scope.order(updated_at: :desc).first
        end

        def preloads_by_props(scope, props)
          preloads = Set.new
          props = property_names if props.blank?

          if props.include?('displayname')
            preloads << :entity
          end

          if props.include?('calendar-data')
            # If you write [:entity, entity: :journals] - first is taken
            #
            # preloads.delete(:entity)

            # Does not work with:
            # `activity_entity.journals.visible.with_notes.pluck(:notes)`
            #
            # preloads << { entity: :journals }

            preloads << :entity
            preloads << :easy_entity_activity_attendees
          end

          # Still missing preload easy_contacts
          # but EasyEntityActivity is polymorphic

          scope.preload(preloads.to_a)
        end

    end
  end
end
