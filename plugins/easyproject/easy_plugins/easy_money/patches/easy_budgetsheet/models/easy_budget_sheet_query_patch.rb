module EasyMoney
  module EasyBudgetSheetQueryPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :available_columns, :easy_money

      end
    end

    module InstanceMethods

      def available_columns_with_easy_money
        columns = available_columns_without_easy_money

        unless @available_columns_with_easy_money_added
          EasyMoneyRateType.rate_type_cache.each do |rate_type|
            if User.current.allowed_to_globally?("easy_budgetsheet_view_#{rate_type.name}_rates".to_sym)
              sql = proc { Arel::Nodes::Grouping.new(emtee_select_manager(rate_type)).to_sql }
              column_name = (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name).to_sym

              columns << EasyQueryCurrencyColumn.new(column_name, sumable: :bottom, sumable_sql: sql, sortable: sql, query: self, preload: [easy_money_time_entry_expenses: :project])
            end
          end

          @available_columns_with_easy_money_added = true
        end

        columns
      end

      def emtee_select_manager(rate_type)
        easy_money_time_enty_expenses_table = EasyMoneyTimeEntryExpense.arel_table
        time_entries_table = TimeEntry.arel_table

        Arel::SelectManager.new(easy_money_time_enty_expenses_table).tap do |manager|
          manager.where easy_money_time_enty_expenses_table[:rate_type_id].eq(rate_type.id)
          manager.where easy_money_time_enty_expenses_table[:time_entry_id].eq(time_entries_table[:id])

          price_column_name = 'price'

          if easy_currency_code.present?
            price_column_name = "price_#{easy_currency_code}"
          end

          manager.projections << easy_money_time_enty_expenses_table[price_column_name].sum
        end
      end

    end

  end
end

EasyExtensions::PatchManager.register_model_patch 'EasyBudgetSheetQuery', 'EasyMoney::EasyBudgetSheetQueryPatch', if: -> { Redmine::Plugin.installed?(:easy_budgetsheet) }
