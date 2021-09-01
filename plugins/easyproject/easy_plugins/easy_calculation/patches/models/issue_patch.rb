module EasyCalculations
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        safe_attributes 'calculation_rate', 'calculation_discount', 'calculation_discount_is_percent', 'calculation_unit'

        validates :calculation_rate, :calculation_discount, :numericality => true, :allow_nil => true

      end
    end

    module InstanceMethods

      def add_to_easy_calculations
        update_column(:in_easy_calculation, true)
      end

      def remove_from_easy_calculations
        update_column(:in_easy_calculation, false)
      end

      def in_easy_calculation_tracker?
        settings = EasySetting.value(:calculation)
        if settings && settings[:tracker_ids] && settings[:tracker_ids].include?(self.tracker_id)
          return true
        end
        return false
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyCalculations::IssuePatch'
