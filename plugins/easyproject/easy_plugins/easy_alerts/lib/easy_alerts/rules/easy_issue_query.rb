module EasyAlerts
  module Rules

    class EasyIssueQuery < EasyAlerts::Rules::EasyQuery

      def find_items(alert, user=nil)
        user ||= User.current

        q = ::EasyIssueQuery.where(:id => self.query_id).first
        if q
          q.entity_scope = Issue.visible(user)
          q.entity_scope = q.entity_scope.alerts_active_projects if active_projects_only
          alert_query_rules_condition(q, alert)
        end
      end

      def mailer_template_name(alert)
        if alert.mail_for == 'all'
          :alert_reports_easy_query_for_all
        else
          :alert_reports_easy_query_for_group
        end
      end

      def issue_provided?
        true
      end

    end

  end
end
