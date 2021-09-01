module EasyCrm
  module EasyPriceBookRecordPatch
    def self.included(base)
      base.class_eval do
        belongs_to :easy_crm_case_item, foreign_key: :entity_id, foreign_type: 'EasyCrmCaseItem'
        has_one :easy_crm_case, through: :easy_crm_case_item
        has_many(:easy_contacts, through: :easy_crm_case) if Redmine::Plugin.installed?(:easy_contacts)


      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyPriceBookRecord', 'EasyCrm::EasyPriceBookRecordPatch', if: proc { Redmine::Plugin.installed?(:easy_price_books) }
