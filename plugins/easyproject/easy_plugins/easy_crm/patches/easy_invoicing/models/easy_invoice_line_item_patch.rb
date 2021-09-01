module EasyCrm
  module EasyInvoiceLineItemPatch
    def self.included(base)
      base.class_eval do

        has_one :easy_crm_case, through: :easy_invoice

      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceLineItem', 'EasyCrm::EasyInvoiceLineItemPatch', first: true, if: proc { Redmine::Plugin.installed?(:easy_invoicing) }
