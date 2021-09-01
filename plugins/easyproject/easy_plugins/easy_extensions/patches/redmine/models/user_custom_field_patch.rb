module EasyPatch
  module UserCustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_and_belongs_to_many :easy_user_types, :join_table => "#{table_name_prefix}custom_fields_easy_user_types#{table_name_suffix}", :foreign_key => "custom_field_id"

        safe_attributes 'easy_user_type_ids'

        alias_method_chain :visible_by?, :easy_extensions

        def form_fields
          super + [:clear_when_anonymize]
        end

        class << self

          def customized_class
            Principal
          end

        end

      end
    end

    module InstanceMethods

      def visible_by_with_easy_extensions?(project, user = User.current)
        user.admin? || visible? || easy_user_type_ids.include?(user.easy_user_type_id)
      end

    end

    module ClassMethods
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'UserCustomField', 'EasyPatch::UserCustomFieldPatch'
