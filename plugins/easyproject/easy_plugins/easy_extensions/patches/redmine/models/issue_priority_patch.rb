module EasyPatch
  module IssuePriorityPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        acts_as_easy_translate

        alias_method_chain :transfer_relations, :easy_extensions

      end
    end

    module InstanceMethods

      def transfer_relations_with_easy_extensions(to)
        issues.where(easy_is_repeating: false).update_all(priority_id: to.id)
        issues.where(easy_is_repeating: true).each do |issue|
          repeat_settings = issue.easy_repeat_settings
          if repeat_settings.try(:[], 'entity_attributes').try(:[], 'priority_id').to_i == id
            repeat_settings = repeat_settings.deep_merge('entity_attributes' => { 'priority_id' => to.id })
            issue.update_columns(priority_id: to.id, easy_repeat_settings: repeat_settings)
          else
            issue.update_column(:priority_id, to.id)
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssuePriority', 'EasyPatch::IssuePriorityPatch'
