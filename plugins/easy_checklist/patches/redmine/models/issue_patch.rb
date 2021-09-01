module EasyChecklistPlugin
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        include EasyPatch::Acts::ActsAsEasyChecklist
        acts_as_easy_checklist

      end
    end

    module InstanceMethods

      def update_easy_checklist_done_ratio(ratio)
        begin
          self.update_attribute(:done_ratio, ratio.round(-1)) # round to ten
        rescue ActiveRecord::StaleObjectError
          self.reload
          self.update_attribute(:done_ratio, ratio.round(-1)) # round to ten
        end
      end

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'Issue', 'EasyChecklistPlugin::IssuePatch'
