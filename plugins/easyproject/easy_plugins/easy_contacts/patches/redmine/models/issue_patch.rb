module EasyContactPatch
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_contact_entity_assignments, :as => :entity, :dependent => :destroy
        has_many :easy_contacts, :through => :easy_contact_entity_assignments

        before_create :assign_contacts

        def assign_contacts
          emails = []
          emails += self.easy_email_to.scan(EasyExtensions::Mailer::EMAIL_REGEXP) if easy_email_to
          emails += self.easy_email_cc.scan(EasyExtensions::Mailer::EMAIL_REGEXP) if easy_email_cc
          emails.uniq!
          return true if emails.empty?

          like_statement = emails.map{|email| "custom_values.value LIKE '%#{email}%'"}.join(' OR ')

          contacts = EasyContact.includes(custom_values: :custom_field).
            where(custom_fields: {field_format: :email}).
            where(like_statement).distinct

          return if contacts.empty?

          self.easy_contacts << contacts
        end

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyContactPatch::IssuePatch'
