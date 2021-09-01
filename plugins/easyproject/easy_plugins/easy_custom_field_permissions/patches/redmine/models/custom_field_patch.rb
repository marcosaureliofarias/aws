module EasyCustomFieldPermissions
  module CustomFieldPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :visible_by?, :easy_custom_field_permissions

        class << self
          alias_method_chain :visible, :easy_custom_field_permissions

          def permitted_custom_fields
            all.select {|cf| cf.permitted_custom_field? }
          end

        end

        store :easy_custom_permissions, accessors: [:allowed_group_ids, :allowed_easy_user_type_ids, :allowed_user_ids, :special_visibility], coder: JSON

        safe_attributes 'allowed_group_ids', 'allowed_easy_user_type_ids', 'allowed_user_ids', 'special_visibility'

        def permitted_custom_field?(user = User.current)
          return true if user.admin? || easy_custom_permissions.nil? || !special_visibility_enabled?
          groups_allowed?(user.group_ids) || user_types_allowed?(user.easy_user_type_id) || users_allowed?(user.id)
        end

        def special_visibility_enabled?
          special_visibility.to_boolean
        end

        private

        def groups_allowed?(group_ids)
          allowed_group_ids.present? && (allowed_group_ids.map(&:to_i) & group_ids).present?
        end

        def user_types_allowed?(easy_user_type_id)
          allowed_easy_user_type_ids.present? && allowed_easy_user_type_ids.map(&:to_i).include?(easy_user_type_id)
        end

        def users_allowed?(user_id)
          allowed_user_ids.present? && allowed_user_ids.map(&:to_i).include?(user_id)
        end

      end
    end

    module InstanceMethods

      def visible_by_with_easy_custom_field_permissions?(project, user=User.current)
        visible_by_without_easy_custom_field_permissions?(project, user) && permitted_custom_field?(user)
      end

    end

    module ClassMethods

      def visible_with_easy_custom_field_permissions(*args)
        result = visible_without_easy_custom_field_permissions(*args)
        return result if User.current.admin? || !CustomField.column_names.include?('easy_custom_permissions')
        result.where(id: permitted_custom_fields.map(&:id))
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomField', 'EasyCustomFieldPermissions::CustomFieldPatch'

