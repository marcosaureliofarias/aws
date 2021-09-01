require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class HelpdeskMonitorPrepaidHours < EasyAlerts::Rules::Base
      include Helpers::HelpdeskMonitorRuleHelper

      def find_items(alert, user=nil)
        user ||= User.current

        return unless Object.const_defined?(:EasyHelpdesk)

        p = self.percentage.to_i
        date_begin = Date.today.beginning_of_month
        date_end = Date.today.end_of_month

        scope = Project.
          joins(:easy_helpdesk_project, :time_entries).
          where(["#{Project.table_name}.easy_is_easy_template = ?", false]).
          where(["#{EasyHelpdeskProject.table_name}.monitor_spent_time = ?", true]).
          where("#{EasyHelpdeskProject.table_name}.monthly_hours IS NOT NULL AND #{EasyHelpdeskProject.table_name}.monthly_hours <> 0").
          where("#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", date_begin, date_end)
        scope = scope.active if active_projects_only
        scope.
          group("#{Project.table_name}.id").
          having("(SUM(#{TimeEntry.table_name}.hours) / MIN(#{EasyHelpdeskProject.table_name}.monthly_hours)) * 100 >= ?", p).to_a
      end

    end

  end
end
