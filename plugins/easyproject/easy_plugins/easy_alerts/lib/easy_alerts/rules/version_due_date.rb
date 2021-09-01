require 'easy_alerts/rules/helpers/version_rule_helper'

module EasyAlerts
  module Rules

    class VersionDueDate < EasyAlerts::Rules::DateBase
      include Helpers::VersionRuleHelper

      def find_items(alert, user=nil)
        user ||= User.current

        scope = ::Version.visible(user).where(["#{Project.table_name}.easy_is_easy_template = ?", false])
        scope = scope.where(["#{Version.table_name}.id IN (?)", self.version_ids])
        scope = scope.alerts_active_projects if active_projects_only

        if alert.rule_settings[:date_type] == 'date'
          unless self.get_date == Date.today
            scope = scope.none
          end
        else
          scope = scope.where(["#{Version.table_name}.effective_date = ?", self.get_date])
        end

        scope.all
      end

    end

  end
end
