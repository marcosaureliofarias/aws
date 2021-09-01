module EasyContactPatch
  module EasyUserTypePatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :copy, :easy_contact

        has_and_belongs_to_many :easy_contact_types, join_table: 'easy_contact_types_easy_user_types'

        safe_attributes 'easy_contact_type_ids'

        def easy_contact_type_ids=(contact_types)
          if contact_types.is_a?(Array) && contact_types.include?('all')
            super(EasyContactType.all.pluck(:id))
          else
            super(contact_types)
          end
        end

      end
    end

    module InstanceMethods

      def copy_with_easy_contact
        user_type_copied = copy_without_easy_contact
        user_type_copied.easy_contact_types = self.easy_contact_types
        user_type_copied
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyUserType', 'EasyContactPatch::EasyUserTypePatch'
