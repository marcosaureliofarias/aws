module EasyCrmPatch
  module CustomValuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        after_save :ensure_easy_crm_case

        private

        def ensure_easy_crm_case
          c = self.custom_field
          if c.field_format == 'easy_lookup' && c.settings['entity_type'] == 'EasyCrmCase' && self.value
            easy_crm_cases = EasyCrmCase.where(:id => Array(self.value)).to_a

            # if self is project then it move crm case to another project
            if self.customized.is_a?(Issue) && self.customized.class.reflections.key?('easy_crm_cases')
              begin
                self.customized.easy_crm_cases += easy_crm_cases
              rescue ActiveRecord::RecordNotUnique
              end
            end
          end
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomValue', 'EasyCrmPatch::CustomValuePatch'
