module EasyBudgetsheet
  module TimeReportPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :load_available_criteria, :easy_budgetsheet
      end
    end

    module InstanceMethods
      def load_available_criteria_with_easy_budgetsheet
        load_available_criteria_without_easy_budgetsheet
        if EasySetting.value('show_billable_things')
          @available_criteria['billable'] = {:sql => "#{TimeEntry.table_name}.easy_is_billable", :label => :field_easy_is_billable}
          @available_criteria['billed'] = {:sql => "#{TimeEntry.table_name}.easy_billed", :label => :field_easy_billed}
        end
        @available_criteria
      end
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Helpers::TimeReport', 'EasyBudgetsheet::TimeReportPatch'
