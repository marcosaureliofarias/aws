module EasyCrm
  module EasyMoneyEntityPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do

        class << self
          alias_method_chain :allowed_entities, :easy_crm_case
        end
      end
    end

    module ClassMethods

      def allowed_entities_with_easy_crm_case(project = nil)
        allowed_entities = allowed_entities_without_easy_crm_case(project)
        if project
          allowed_entities << 'EasyCrmCase' if project.easy_money_settings.use_easy_money_for_easy_crm_cases?
        else
          allowed_entities << 'EasyCrmCase'
        end
        allowed_entities
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyMoneyEntity', 'EasyCrm::EasyMoneyEntityPatch', if: Proc.new { Redmine::Plugin.installed?(:easy_money) }
