module EasyCrm
  module EasyInvoiceLineItemQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :available_columns, :easy_crm
      end
    end

    module InstanceMethods
      def available_columns_with_easy_crm
        available_columns_without_easy_crm

        unless @available_invoicing_columns_added
          add_associated_columns EasyCrmCaseQuery, association_name: :easy_crm_case

          @available_invoicing_columns_added = true
        end

        @available_columns
      end
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceLineItemQuery', 'EasyCrm::EasyInvoiceLineItemQueryPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
