module EasyMoney
  module EasyEntityAssignmentPatch

    def self.included(base)
      base.class_eval do
        belongs_to :easy_money_other_revenue, foreign_key: 'entity_to_id', dependent: :destroy
        belongs_to :easy_money_expected_revenue, foreign_key: 'entity_to_id', dependent: :destroy
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyEntityAssignment', 'EasyMoney::EasyEntityAssignmentPatch', if: proc { Redmine::Plugin.installed?(:easy_invoicing) }
