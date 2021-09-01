module EasyAlerts
  module Rules

    class EasyProjectQuery < EasyAlerts::Rules::EasyQuery

      def find_items(alert, user=nil)
        user ||= User.current

        q = ::EasyProjectQuery.find_by(id: self.query_id)
        if q
          q.entity_scope = Project.visible(user)
          q.entity_scope = q.entity_scope.active if active_projects_only
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

    end

  end
end
