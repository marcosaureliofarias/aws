module EasyContacts
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_contact_groups, :as => :entity, :dependent => :destroy

        has_many :easy_contact_entity_assignments, :as => :entity, :dependent => :destroy
        has_many :easy_contacts, :through => :easy_contact_entity_assignments,  :after_remove => :reglobalize_contact

        safe_attributes 'easy_contact_ids'

        def copy_easy_contacts(source_project)
# TODO
#          source_project.easy_contact_groups.each do |easy_contact_group|
#            copy = easy_contact_group.dup
#            copy.entity_id = self.id
#            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, easy_contact_group: #{easy_contact_group.id} )") if !copy.save && logger
#          end
#
#          source_project.easy_contacts.each do |easy_contact|
#            copy = easy_contact.dup
#            #copy.entity_id = self.id
#            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, easy_contact: #{easy_contact.id} )") if !copy.save && logger
#          end
        end

        private

        def reglobalize_contact(contact)
          if contact.easy_contact_entity_assignments.empty?
            contact.update_attributes(:is_global => true)
          end
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch('Project', 'EasyContacts::ProjectPatch')
