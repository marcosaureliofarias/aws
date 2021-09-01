require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class HelpdeskMonitorDueTimeAssignee < EasyAlerts::Rules::Base
      include Helpers::HelpdeskMonitorRuleHelper

      def find_items(alert, user=nil)
        return unless Object.const_defined?(:EasyHelpdesk)
        user ||= User.current

        p = self.percentage.to_i
        issues = []

        scope = Issue.visible(user).joins(:status).eager_load(:project => :easy_helpdesk_project).preload(:easy_helpdesk_project_sla).
          where(["#{EasyHelpdeskProject.table_name}.monitor_due_date = ?", true]).
          where(["#{IssueStatus.table_name}.is_closed = ?", false]).
          where(["#{Project.table_name}.easy_is_easy_template = ?", false]).
          where(["#{Issue.table_name}.assigned_to_id = ?", user.id]).
          where(["#{Issue.table_name}.easy_helpdesk_project_sla_id IS NOT NULL"]).
          where(["#{Issue.table_name}.easy_due_date_time IS NOT NULL"])
        scope = scope.alerts_active_projects if active_projects_only
        scope.find_each(:batch_size => 500) do |issue|

          if (sla = issue.easy_helpdesk_project_sla) && sla.hours_to_solve
            alert_difference = sla.hours_to_solve.to_f / 100 * (100 - p)
            alert_at = if sla.use_working_time
              issue.easy_helpdesk_project_sla_date_time_with_working_time(sla, sla.hours_to_solve.to_f - alert_difference, issue.easy_sla_pause(sla))
            else
              issue.easy_due_date_time - alert_difference.hours
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
