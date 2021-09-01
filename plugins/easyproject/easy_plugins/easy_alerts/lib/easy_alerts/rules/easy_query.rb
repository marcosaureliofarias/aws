require 'easy_alerts/alert_rules'
require 'easy_alerts/rules/helpers/hours_time_check_helper'
require 'easy_alerts/rules/helpers/easy_query_rule_helper'

module EasyAlerts
  module Rules

    class EasyQuery < EasyAlerts::Rules::Base
      include Helpers::HoursTimeCheckHelper
      include Helpers::EasyQueryRuleHelper

      def expires_at(alert)
        if alert.rule_settings[:operator] != '>'
          Time.now
        else
          super
        end
      end

    end

  end
end
