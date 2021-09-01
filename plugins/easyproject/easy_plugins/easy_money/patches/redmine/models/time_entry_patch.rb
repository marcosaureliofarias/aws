module EasyMoney
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        has_many :easy_money_time_entry_expenses, :class_name => 'EasyMoneyTimeEntryExpense', :foreign_key => 'time_entry_id', :dependent => :destroy

        after_save :update_easy_money_time_entry_expense

        def update_easy_money_time_entry_expense
          EasyMoneyTimeEntryExpense.update_easy_money_time_entry_expense(self) if self.project.module_enabled?(:easy_money) && !self.new_record?
        end

        def easymoney_hours
          hours
        end

        # Dynamically create method for *rates*.
        # * internal
        # * external
        EasyMoneyRateType.rate_type_cache.each_with_index do |rate_type, i|
          self.send(:define_method, EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name) do |currency = nil|
            if self.easy_money_time_entry_expenses[i]
              return self.easy_money_time_entry_expenses[i].send(currency ? 'price_' + currency : 'price')
            end
          end
        end if EasyMoneyRateType.table_exists?

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyMoney::TimeEntryPatch'
