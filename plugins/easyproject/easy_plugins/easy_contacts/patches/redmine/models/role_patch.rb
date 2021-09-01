module EasyContacts
  module RolePatch

    def self.included(base)
      base.class_eval do

        const_set(:EASY_CONTACTS_VISIBILITY_OPTIONS, [
            ['all', :label_easy_contacts_visibility_all],
            ['own', :label_easy_contacts_visibility_own],
            ['author', :label_easy_contacts_visibility_author],
            ['assigned', :label_easy_contacts_visibility_assigned]
        ])

        validates_inclusion_of :easy_contacts_visibility,
                               in: Role::EASY_CONTACTS_VISIBILITY_OPTIONS.collect(&:first),
                               if: lambda {|role| role.respond_to?(:easy_contacts_visibility) && role.easy_contacts_visibility_changed?}

        safe_attributes 'easy_contacts_visibility'

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Role', 'EasyContacts::RolePatch'
