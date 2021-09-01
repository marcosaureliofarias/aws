module EasyMoney
  module EasyInvoiceQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize_available_columns, :easy_money
      end
    end

    module InstanceMethods
      def initialize_available_columns_with_easy_money
        initialize_available_columns_without_easy_money
        @available_columns << EasyQueryColumn.new(:easy_money_other_revenue, :sortable => "#{EasyMoneyOtherRevenue.table_name}.name", :caption => :label_filter_group_easy_money_other_revenue_query, :includes => [:easy_money_other_revenues]) if User.current.allowed_to?(:easy_money_show_other_revenue, nil, :global => true)
        @available_money_columns_added = true
      end
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceQuery', 'EasyMoney::EasyInvoiceQueryPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
