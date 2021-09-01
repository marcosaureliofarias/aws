require 'easy_alerts/alert_rules'
require 'easy_alerts/rules/helpers/date_rule_helper'

module EasyAlerts
  module Rules

    class DateBase < EasyAlerts::Rules::Base
      include Helpers::DateRuleHelper

      def expires_at(_)
        Time.now.end_of_day
      end

    end

  end
end
