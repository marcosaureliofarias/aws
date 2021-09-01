module EasyBudgetsheet
  module EasyTimeEntryBaseQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :available_columns, :easy_budgetsheet
        alias_method_chain :available_filters, :easy_budgetsheet

      end
    end

    module InstanceMethods

      def available_columns_with_easy_budgetsheet
        c = available_columns_without_easy_budgetsheet
        if EasySetting.value('show_billable_things') && !@new_columns_added_easy_budgetsheet
          group = l(:label_filter_group_easy_time_entry_query)

          c << EasyQueryColumn.new(:easy_is_billable, :sortable => "#{TimeEntry.table_name}.easy_is_billable", :groupable => true, :group => group)
          c << EasyQueryColumn.new(:easy_billed, :sortable => "#{TimeEntry.table_name}.easy_billed", :groupable => true, :group => group)

          @new_columns_added_easy_budgetsheet = true
        end

        return c
      end

      def available_filters_with_easy_budgetsheet
        f = available_filters_without_easy_budgetsheet
        if EasySetting.value('show_billable_things') && !@new_filters_added_easy_budgetsheet

          group = l(:label_filter_group_easy_time_entry_query)

          f['easy_is_billable'] = { :type => :boolean, :order => 30, :group => group }
          f['easy_billed'] = { :type => :boolean, :order => 31, :group => group }

          @new_filters_added_easy_budgetsheet = true
        end

        return f
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyTimeEntryBaseQuery', 'EasyBudgetsheet::EasyTimeEntryBaseQueryPatch'
