module EasyGanttResources
  module UserPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        after_save :update_easy_gantt_resources_estimated_ratio,      if: :easy_gantt_resources_estimated_ratio_changed?
        after_save :update_easy_gantt_resources_hours_limit,          if: :easy_gantt_resources_hours_limit_changed?
        after_save :update_easy_gantt_resources_advance_hours_limits, if: :easy_gantt_resources_advance_hours_limits_changed?
      end
    end

    module InstanceMethods
      # estimated ratio

      def easy_gantt_resources_estimated_ratio
        @easy_gantt_resources_estimated_ratio ||= EasySetting.value(:easy_gantt_resources_users_estimated_ratios) && EasySetting.value(:easy_gantt_resources_users_estimated_ratios)[self.id.to_s]
      end

      def easy_gantt_resources_estimated_ratio=(value)
        @easy_gantt_resources_estimated_ratio_changed = true
        @easy_gantt_resources_estimated_ratio = value
      end

      def easy_gantt_resources_estimated_ratio_changed?
        @easy_gantt_resources_estimated_ratio_changed ||= false
      end

      # hours limit

      def easy_gantt_resources_hours_limit
        @easy_gantt_resources_hours_limit ||= EasySetting.value(:easy_gantt_resources_users_hours_limits) && EasySetting.value(:easy_gantt_resources_users_hours_limits)[self.id.to_s]
      end

      def easy_gantt_resources_hours_limit=(value)
        @easy_gantt_resources_hours_limit_changed = true
        @easy_gantt_resources_hours_limit = value
      end

      def easy_gantt_resources_hours_limit_changed?
        @easy_gantt_resources_hours_limit_changed ||= false
      end

      # advance hours limit

      def easy_gantt_resources_advance_hours_limits
        @easy_gantt_resources_advance_hours_limits ||= EasySetting.value(:easy_gantt_resources_users_advance_hours_limits) && EasySetting.value(:easy_gantt_resources_users_advance_hours_limits)[self.id.to_s]
      end

      def easy_gantt_resources_advance_hours_limits=(value)
        @easy_gantt_resources_advance_hours_limits_changed = true
        if value.is_a?(Array)
          @easy_gantt_resources_advance_hours_limits = value
        elsif value.respond_to?(:to_a)
          @easy_gantt_resources_advance_hours_limits = value.to_a
        else
          @easy_gantt_resources_advance_hours_limits = Array(value)
        end
      end

      def easy_gantt_resources_advance_hours_limits_changed?
        @easy_gantt_resources_advance_hours_limits_changed ||= false
      end

      private

      def update_easy_gantt_resources_estimated_ratio
        setting = EasySetting.find_or_initialize_by(name: :easy_gantt_resources_users_estimated_ratios)
        setting.value ||= {}
        setting.value[self.id.to_s] = easy_gantt_resources_estimated_ratio
        setting.save.tap { |success| @easy_gantt_resources_estimated_ratio_changed = false if success }
      end

      def update_easy_gantt_resources_hours_limit
        setting = EasySetting.find_or_initialize_by(name: :easy_gantt_resources_users_hours_limits)
        setting.value ||= {}
        setting.value[self.id.to_s] = easy_gantt_resources_hours_limit
        setting.save.tap { |success| @easy_gantt_resources_hours_limit_changed = false if success }
      end

      def update_easy_gantt_resources_advance_hours_limits
        setting = EasySetting.find_or_initialize_by(name: :easy_gantt_resources_users_advance_hours_limits)
        setting.value ||= {}
        setting.value[self.id.to_s] = easy_gantt_resources_advance_hours_limits
        setting.save.tap { |success| @easy_gantt_resources_advance_hours_limits_changed = false if success }
      end
    end

    module ClassMethods
    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'User', 'EasyGanttResources::UserPatch'
