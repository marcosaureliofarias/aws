require 'easy_alerts/rules/helpers/invoice_rule_helper'

module EasyAlerts
  module Rules

    class InvoiceDueDate < EasyAlerts::Rules::DateBase
      include Helpers::InvoiceRuleHelper

      def find_items(alert, user=nil)
        user ||= User.current
        return unless Redmine::Plugin.installed?(:easy_invoicing)

        scope = ::EasyInvoice.accounting_documents.visible(user)
        scope = scope.where(["#{EasyInvoice.table_name}.project_id IN (?)", self.projects]) unless self.projects.blank?
        scope = scope.alerts_active_projects if active_projects_only

        if alert.rule_settings[:date_type] == 'date'
          unless self.get_date == Date.today
            scope = scope.none
          end
        else
          scope = scope.where(["#{EasyInvoice.table_name}.due_at = ?", self.get_date])
        end

        scope.to_a
      end

    end

  end
end
