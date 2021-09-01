module EasyContactPatch
  module EasyEntityActivityPatch

    def self.included(base)

      base.class_eval do

        belongs_to :easy_contact, ->{ joins("INNER JOIN #{EasyEntityActivity.table_name} ON #{EasyEntityActivity.table_name}.entity_type = 'EasyContact' AND #{EasyEntityActivity.table_name}.entity_id = #{EasyContact.table_name}.id")}, foreign_key: :entity_id
        alias_method :easy_contact, :entity
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyEntityActivity', 'EasyContactPatch::EasyEntityActivityPatch'
