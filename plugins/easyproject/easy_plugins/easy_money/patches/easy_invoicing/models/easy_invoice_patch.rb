module EasyMoney
  module EasyInvoicePatch

    def self.included(base)
      base.class_eval do
        has_many :easy_money_other_revenues, through: :easy_entity_assignments, source: :entity_to, source_type: 'EasyMoneyOtherRevenue', dependent: :destroy
        has_many :easy_money_expected_revenues, through: :easy_entity_assignments, source: :entity_to, source_type: 'EasyMoneyExpectedRevenue', dependent: :destroy

        after_commit :save_easy_money_expected_revenue, if: proc { is_open_real_invoice? && EasySetting.value(:create_planned_budget_entries_on_base_of_created_invoices, project) }
        after_commit :save_easy_money_other_revenue, if: proc { is_open_real_invoice? && EasySetting.value(:create_real_incomes_when_invoice_is_paid, project) }

        after_save :destroy_money_entities_on_cancel, if: proc {|i| !i.is_template? && i.accounting_document? }

        def is_open_real_invoice?
          !is_template? && accounting_document? && !status.cancelled?
        end

        def easy_money_expected_revenue
          self.easy_money_expected_revenues.first
        end

        def easy_money_other_revenue
          self.easy_money_other_revenues.first
        end

        def save_easy_money_expected_revenue
          easy_money_expected_revenue = self.easy_money_expected_revenue
          easy_money_expected_revenue ||= EasyMoneyExpectedRevenue.new(
            name: "#{l(:label_easy_invoice, locale: self.default_locale)}-#{self.number}",
            entity_type: 'Project', entity_id: self.project_id
          )
          easy_money_expected_revenue.spent_on = (taxable_fulfillment_due_at || self.paid_at || self.issued_at || User.current.today).to_date
          if self.total && self.subtotal && !self.subtotal.zero?
            easy_money_expected_revenue.price1 = self.total(self.project.easy_currency_code)
            easy_money_expected_revenue.price2 = self.subtotal(self.project.easy_currency_code)
            easy_money_expected_revenue.vat = easy_money_expected_revenue.calculate_vat
          end
          self.easy_money_expected_revenues = [easy_money_expected_revenue]
          easy_money_expected_revenue.save
        end

        def save_easy_money_other_revenue
          if (paid_at = begin; self.paid_at.try(:to_date); rescue ArgumentError; end)
            easy_money_other_revenue = self.easy_money_other_revenue
            easy_money_other_revenue ||= EasyMoneyOtherRevenue.new(
              name: "#{l(:label_easy_invoice, locale: self.default_locale)}-#{self.number}",
              entity_type: 'Project', entity_id: self.project_id
            )
            easy_money_other_revenue.spent_on = paid_at
            if self.total && self.subtotal && !self.subtotal.zero?
              easy_money_other_revenue.price1 = self.total(self.project.easy_currency_code)
              easy_money_other_revenue.price2 = self.subtotal(self.project.easy_currency_code)
              easy_money_other_revenue.vat = easy_money_other_revenue.calculate_vat
            end
            self.easy_money_other_revenues = [easy_money_other_revenue]
            easy_money_other_revenue.save
          end

          true
        end

        def destroy_money_entities_on_cancel
          return unless self.saved_change_to_easy_invoice_status_id? && self.status.cancelled?
          self.easy_money_expected_revenues.each(&:destroy)
          self.easy_money_other_revenues.each(&:destroy)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceDocument', 'EasyMoney::EasyInvoicePatch', if: proc { Redmine::Plugin.installed?(:easy_invoicing) }
