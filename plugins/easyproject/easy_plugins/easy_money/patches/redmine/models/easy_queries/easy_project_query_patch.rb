module EasyMoney
  module EasyProjectQueryPatch

    def self.included(base)

      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize_available_columns, :easy_money
      end
    end

    module InstanceMethods
      def initialize_available_columns_with_easy_money
        initialize_available_columns_without_easy_money
        add_available_column 'easy_money.cost_ratio', title: l(:field_cost_ratio), group: l(:easy_money_plugin_name)
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyProjectQuery', 'EasyMoney::EasyProjectQueryPatch'