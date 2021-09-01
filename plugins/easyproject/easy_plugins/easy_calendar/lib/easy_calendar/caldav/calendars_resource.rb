module EasyCalendar
  module Caldav
    class CalendarsResource < Resource

      def collection?
        true
      end

      def property_names
        ['resourcetype'].freeze
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND'].freeze
      end

      def children
        resources = [
          EasyMeetingsResource.new('/easy_meeting', controller)
        ]

        if EasyCalendar.extended_caldav?
          resources << IssuesResource.new('/issues', controller)
          resources << VersionsResource.new('/versions', controller)

          if Redmine::Plugin.installed?(:easy_crm)
            resources << EasyCrmCasesResource.new('/easy_crm_cases', controller)
            resources << EasyCrmCaseContractsResource.new('/easy_crm_cases_contracts', controller)
            resources << SalesActivitiesResource.new('/sales_activities', controller)
          end

          if Redmine::Plugin.installed?(:easy_attendances) && EasyAttendance.enabled?
            resources << EasyAttendancesResource.new('/easy_attendances', controller)
          end
        end

        resources
      end

    end
  end
end
