module EasyCrm
  module RolePatch

    def self.included(base)
      base.class_eval do

        const_set(:EASY_CRM_CASES_VISIBILITY_OPTIONS, [
            ['all', :label_easy_crm_cases_visibility_all],
            ['own', :label_easy_crm_cases_visibility_own]
        ])

        validates_inclusion_of :easy_crm_cases_visibility,
                               in: Role::EASY_CRM_CASES_VISIBILITY_OPTIONS.collect(&:first),
                               if: lambda {|role| role.respond_to?(:easy_crm_cases_visibility) && role.easy_crm_cases_visibility_changed?}

        safe_attributes 'easy_crm_cases_visibility'

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Role', 'EasyCrm::RolePatch'
