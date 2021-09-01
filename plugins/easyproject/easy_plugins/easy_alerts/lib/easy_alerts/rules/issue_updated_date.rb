require 'easy_alerts/rules/helpers/issue_rule_helper'

module EasyAlerts
  module Rules

    class IssueUpdatedDate < EasyAlerts::Rules::DateBase
      include Helpers::IssueRuleHelper

      def find_items(alert, user=nil)
        user ||= User.current

        scope = ::Issue.visible(user)
        scope = scope.where(id: self.issue_ids)

        if alert.rule_settings[:date_type] == 'date'
          unless self.get_date == Date.today
            scope = scope.none
          end
        else
          scope = scope.where(updated_on: self.get_date.beginning_of_day..self.get_date.end_of_day)
        end

        scope = scope.alerts_active_projects if active_projects_only

        scope.all
      end

      def issue_provided?
        true
      end

    end

  end
end
