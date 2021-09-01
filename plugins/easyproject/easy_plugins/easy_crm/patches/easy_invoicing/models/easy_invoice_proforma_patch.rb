module EasyCrm
  module EasyInvoiceProformaPatch
    def self.included(base)
      base.class_eval do
        base.include(InstanceMethods)

        alias_method_chain :new_full_invoice, :easy_crm

      end
    end
    module InstanceMethods
      def new_full_invoice_with_easy_crm
        crm_easy_invoice = new_full_invoice_without_easy_crm
        crm_easy_invoice.easy_crm_case = self.easy_crm_case
        crm_easy_invoice
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceProforma', 'EasyCrm::EasyInvoiceProformaPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
