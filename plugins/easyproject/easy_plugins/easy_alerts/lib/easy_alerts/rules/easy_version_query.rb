module EasyAlerts
  module Rules

    class EasyVersionQuery < EasyAlerts::Rules::EasyQuery

      def find_items(alert, user=nil)
        user ||= User.current

        q = ::EasyVersionQuery.find_by(id: self.query_id)
        if q
          return if q.project && active_projects_only && !q.project.active?
          q.entity_scope = q.project.nil? ? Version.visible(user).where(["#{Project.table_name}.easy_is_easy_template = ?", false]) : q.project.shared_versions
          q.entity_scope = q.entity_scope.alerts_active_projects if active_projects_only
          alert_query_rules_condition(q, alert)
        end
      end

    end

  end
end
