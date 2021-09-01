module EasyCrm
  module EasyInvoicePatch
    def self.included(base)
      base.class_eval do
        has_one :easy_crm_case_assignment, -> {where(entity_to_type: 'EasyCrmCase')}, as: :entity_from, class_name: 'EasyEntityAssignment'
        has_one :easy_crm_case, through: :easy_crm_case_assignment, source: :entity_to, source_type: 'EasyCrmCase'
        has_many :easy_crm_cases, through: :easy_crm_case_assignment, source: :entity_to, source_type: 'EasyCrmCase'

        safe_attributes 'easy_crm_case_id'

        def easy_crm_case_id
          self.easy_crm_case ? self.easy_crm_case.id : nil
        end

        def easy_crm_case_id=(easy_crm_case_id)
          self.easy_crm_case = EasyCrmCase.where(id: easy_crm_case_id).first
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceDocument', 'EasyCrm::EasyInvoicePatch', first: true, if: proc { Redmine::Plugin.installed?(:easy_invoicing) }
