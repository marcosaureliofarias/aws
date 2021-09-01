module EasyBudgetsheet
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        before_save :check_easy_is_billable

        safe_attributes 'easy_is_billable', 'easy_billed'

        alias_method_chain :should_validate_time_entry_for_workers?, :easy_budgetsheet

        def easy_is_billable?
          !!(self.easy_is_billable.nil? ? EasySetting.value('billable_things_default_state') : self.easy_is_billable)
        end

        private

        def check_easy_is_billable
          self.easy_is_billable = self.easy_is_billable?
          if !self.easy_is_billable? && self.easy_billed?
            self.easy_billed = '0'
          end
        end

      end
    end

    module InstanceMethods

      def should_validate_time_entry_for_workers_with_easy_budgetsheet?
        original = should_validate_time_entry_for_workers_without_easy_budgetsheet?

        return original unless self.class.column_names.include?('easy_is_billable')

        if original && (easy_is_billable_changed? || easy_billed_changed?) && !(project_id_changed? || user_id_changed? || issue_id_changed? || hours_changed? || activity_id_changed? || spent_on_changed?)
          return false
        else
          original
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyBudgetsheet::TimeEntryPatch'
