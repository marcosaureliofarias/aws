module EasyCalendar
  module Caldav
    class Controller < EasyExtensions::Webdav::Controller

      NAMESPACES = NAMESPACES.merge(
        'xmlns:d'    => 'DAV:',
        'xmlns:c'    => 'urn:ietf:params:xml:ns:caldav',
        'xmlns:cs'   => 'http://calendarserver.org/ns/',
        'xmlns:ical' => 'http://apple.com/ns/ical/'
      )

      PROP_NAMESPACES = PROP_NAMESPACES.merge(
        'calendar-data' => 'c',
        'supported-calendar-component-set' => 'c',
        'calendar-home-set' => 'c',
        'calendar-user-address-set' => 'c',
        'max-instances' => 'c',
        'getctag' => 'cs',
        'calendar-color' => 'ical',
        'calendar-order' => 'ical'
      )

      # TODO: Nicer case :-)
      def resource_class
        case path_info
        when '/'
          CalendarsResource

        when '/principal'
          PrincipalResource

        # Meetings
        #
        when '/easy_meeting', '/easy_meetings'
          EasyMeetingsResource

        when /\A\/easy_meeting\/[^\/]+\Z/, /\A\/easy_meetings\/[^\/]+\Z/
          case request_method
          when :get, :put, :delete
            EasyMeetingResource
          else
            EasyMeetingsResource
          end

        # Issues
        #
        when '/issues'
          return unless EasyCalendar.extended_caldav?
          IssuesResource

        when /\A\/issues\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          case request_method
          when :get, :put, :delete
            IssueResource
          else
            IssuesResource
          end

        # Versions
        #
        when '/versions'
          return unless EasyCalendar.extended_caldav?
          VersionsResource

        when /\A\/versions\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          case request_method
          when :get, :put, :delete
            VersionResource
          else
            VersionsResource
          end

        # Easy CRM cases
        #
        when '/easy_crm_cases'
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          EasyCrmCasesResource

        when /\A\/easy_crm_cases\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          case request_method
          when :get, :put, :delete
            EasyCrmCaseResource
          else
            EasyCrmCasesResource
          end

        # Easy CRM cases by contract date
        #
        when '/easy_crm_cases_contracts'
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          EasyCrmCaseContractsResource

        when /\A\/easy_crm_cases_contracts\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          case request_method
          when :get, :put, :delete
            EasyCrmCaseContractResource
          else
            EasyCrmCaseContractsResource
          end

        # Sales activities
        #
        when '/sales_activities'
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          SalesActivitiesResource

        when /\A\/sales_activities\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_crm)
          case request_method
          when :get, :put, :delete
            SalesActivityResource.by_path(path_info)
          else
            SalesActivitiesResource
          end

        # Easy attendances
        #
        when '/easy_attendances'
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_attendances) && EasyAttendance.enabled?
          EasyAttendancesResource

        when /\A\/easy_attendances\/[^\/]+\Z/
          return unless EasyCalendar.extended_caldav?
          return unless Redmine::Plugin.installed?(:easy_attendances) && EasyAttendance.enabled?
          case request_method
          when :get, :put, :delete
            EasyAttendanceResource
          else
            EasyAttendancesResource
          end

        end
      end

      def report
        # All requested properties
        props = request_match("//d:prop/*").map(&:name)

        # Get report resources
        report_data =
          case request_body.root.name
          when 'calendar-query'
            # Time range
            time_range = {}
            request_match("//c:calendar-query/c:filter/c:comp-filter[@name='VCALENDAR']/c:comp-filter[@name='VEVENT']/c:time-range/@*").each do |element|
              time_range[element.name] = DateTime.parse(element.value)#.to_time
            end

            resource.report_query(time_range, props: props)

          when 'calendar-multiget'
            hrefs = request_match('//d:href/text()').map { |el|
              href = el.text
              href.sub!(env['SCRIPT_NAME'], '')

              url_unescape(href)
            }
            resource.report_multiget(hrefs, props: props)
          end

        render_multistatus(report_data, props)

        print_request_response
      end

      # Status codes are described in `EasyExtensions::Webdav::Controller`
      def put
        raise Forbidden if resource.collection?

        saved, new_record = resource.put

        if saved
          response['Etag'] = resource.getetag

          if new_record
            status = Created
          else
            status = NoContent
          end
        else
          if resource.is_a?(EntityResource)
            render_error(resource.errors_full_messages)
          end

          status = Conflict
        end

        response.status = status
        print_request_response
      end

      def delete
        raise NotFound unless resource.exist?
        resource.delete
        response.status = NoContent
      end

    end
  end
end
