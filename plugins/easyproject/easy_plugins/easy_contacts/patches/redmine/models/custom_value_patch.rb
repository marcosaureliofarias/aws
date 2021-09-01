module EasyContactPatch
  module CustomValuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        after_save :ensure_easy_contact

        private

        def ensure_easy_contact
          c = self.custom_field
          if c.field_format == 'easy_lookup' && c.settings['entity_type'] == 'EasyContact' && self.value
            easy_contact_ids = EasyContact.where(id: Array(self.value)).pluck(:id)
            if self.customized.class.reflections.key?('easy_contacts')
              assignment_contact_ids = EasyContactEntityAssignment.where(entity_id: self.customized.id, entity_type: self.customized.class.base_class.to_s).pluck(:easy_contact_id)
              (easy_contact_ids - assignment_contact_ids).each do |easy_contact_id|
                EasyContactEntityAssignment.create(entity_id: self.customized.id, entity_type: self.customized.class.base_class.to_s, easy_contact_id: easy_contact_id)
              end
            end
            if !self.customized.is_a?(Project) && self.customized.respond_to?(:project) && self.customized.project
              assignment_contact_ids = EasyContactEntityAssignment.where(entity_id: self.customized.project.id, entity_type: 'Project').pluck(:easy_contact_id)
              (easy_contact_ids - assignment_contact_ids).each do |easy_contact_id|
                EasyContactEntityAssignment.create(entity_id: self.customized.project.id, entity_type: 'Project', easy_contact_id: easy_contact_id)
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
EasyExtensions::PatchManager.register_model_patch 'CustomValue', 'EasyContactPatch::CustomValuePatch'
