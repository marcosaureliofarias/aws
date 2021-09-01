module EasyContacts
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_contact_groups, :as => :entity, :dependent => :destroy

        has_many :easy_contact_entity_assignments, :as => :entity, :dependent => :destroy
        has_many :easy_contacts, :through => :easy_contact_entity_assignments, :after_remove => :reglobalize_contact

        def visible_contact_via_user_type(easy_contact)
          return true if self.admin?
          return false unless self.easy_user_type

          self.easy_user_type.easy_contact_type_ids.include?(easy_contact.type_id)
        end

        def allowed_to_manage_easy_contacts?
          User.current.allowed_to_globally?(:manage_easy_contacts, {}) ||
              User.current.allowed_to_globally?(:manage_author_easy_contacts, {}) ||
              User.current.allowed_to_globally?(:manage_assigned_easy_contacts, {})
        end

        private

        def reglobalize_contact(contact)
          if contact.easy_contact_entity_assignments.empty? && !contact.private?
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
EasyExtensions::PatchManager.register_model_patch('User', 'EasyContacts::UserPatch')
