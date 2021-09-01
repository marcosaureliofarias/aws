require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class HelpdeskMonitorHoursToResponse < EasyAlerts::Rules::Base
      include Helpers::HelpdeskMonitorRuleHelper

      def find_items(alert, user=nil)
        return unless Object.const_defined?(:EasyHelpdesk)

        p = self.percentage.to_i
        issues = []

        scope = Issue.non_templates.joins(:status, :tracker).eager_load(:easy_helpdesk_project_sla).
          where("#{Issue.table_name}.easy_helpdesk_project_sla_id IS NOT NULL").
          where("#{IssueStatus.table_name}.id = #{Tracker.table_name}.default_status_id").
          where("#{EasyHelpdeskProjectSla.table_name}.hours_to_response > 0").
          where(["#{Issue.table_name}.easy_response_date_time IS NOT NULL"])
        scope = scope.alerts_active_projects if active_projects_only
        scope.find_each(:batch_size => 500) do |issue|

          if (sla = issue.easy_helpdesk_project_sla) && sla.hours_to_response
            alert_difference = sla.hours_to_response.to_f / 100 * (100 - p)
            alert_at = if sla.use_working_time
              issue.easy_helpdesk_project_sla_date_time_with_working_time(sla, sla.hours_to_response.to_f - alert_difference, issue.easy_sla_pause(sla))
            else
              issue.easy_response_date_time - alert_difference.hours
            end

            if alert_at <= DateTime.now
              issues << issue
            end
          end
        end
        issues
      end
    end

  end
end
