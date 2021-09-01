module EasyMoney
  module EasyInvoiceTemplateQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :skip_columns, :easy_money
      end
    end

    module InstanceMethods
      def skip_columns_with_easy_money
        skip_columns_without_easy_money << 'easy_money_other_revenue'
      end
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceTemplateQuery', 'EasyMoney::EasyInvoiceTemplateQueryPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
