module EasyCrm
  module EasyEntityActivityPatch

    def self.included(base)

      base.class_eval do

        belongs_to :easy_crm_case, ->{ joins("INNER JOIN #{EasyEntityActivity.table_name} ON #{EasyEntityActivity.table_name}.entity_type = 'EasyCrmCase' AND #{EasyEntityActivity.table_name}.entity_id = #{EasyCrmCase.table_name}.id")}, foreign_key: :entity_id, validate: false
        alias_method :easy_crm_case, :entity
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyEntityActivity', 'EasyCrm::EasyEntityActivityPatch'
