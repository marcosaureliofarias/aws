module EasyAlerts
  module Rules

    class EasyInvoiceQuery < EasyAlerts::Rules::EasyQuery

      def find_items(alert, user=nil)
        user ||= User.current
        return unless Redmine::Plugin.installed?(:easy_invoicing)

        q = ::EasyInvoiceQuery.find_by(id: self.query_id)
        if q
          return if q.project && active_projects_only && !q.project.active?
          q.entity_scope = q.project.nil? ? EasyInvoice.accounting_documents.visible(user) : q.project.easy_invoices.accounting_documents.visible(user)
          q.entity_scope = q.entity_scope.alerts_active_projects if active_projects_only
          alert_query_rules_condition(q, alert)
        end
      end

    end

  end
end
