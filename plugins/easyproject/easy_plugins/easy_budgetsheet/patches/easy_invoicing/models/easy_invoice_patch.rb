module EasyBudgetsheet
  module EasyInvoicePatch

    def self.included(base)
      base.class_eval do
        attr_accessor :time_entry_ids

        safe_attributes 'time_entry_ids'

        after_save :automatic_mark_of_billed_spend_time

        def automatic_mark_of_billed_spend_time
          TimeEntry.where(id: @time_entry_ids).update_all(easy_billed: true) if !@time_entry_ids.nil?
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceDocument', 'EasyBudgetsheet::EasyInvoicePatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
