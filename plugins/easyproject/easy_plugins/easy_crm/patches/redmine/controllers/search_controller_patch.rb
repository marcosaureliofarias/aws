module EasyCrm
  module SearchControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :object_type_allowed_to_condition, :easy_crm
      end
    end

    module InstanceMethods
      def object_type_allowed_to_condition_with_easy_crm(object_type, project)
        object_type = 'easy_crms' if object_type == 'easy_crm_cases'
        object_type_allowed_to_condition_without_easy_crm(object_type, project)
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'SearchController', 'EasyCrm::SearchControllerPatch'
