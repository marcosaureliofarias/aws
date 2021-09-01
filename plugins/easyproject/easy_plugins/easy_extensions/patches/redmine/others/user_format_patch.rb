module EasyPatch
  module UserFormatPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :possible_values_records, :easy_extensions
      end
    end


    module InstanceMethods

      def possible_values_records_with_easy_extensions(custom_field, object = nil)
        if object.nil?
          User.active.visible.sorted
        elsif object.is_a?(Array)
          projects = object.map { |o| o.respond_to?(:project) ? o.project : nil }.compact.uniq
          projects.map { |project| possible_values_records(custom_field, project) }.reduce(:&) || []
        elsif object.respond_to?(:project) && object.project
          scope = object.project.users
          if custom_field.user_role.is_a?(Array)
            role_ids = custom_field.user_role.map(&:to_s).reject(&:blank?).map(&:to_i)
            if role_ids.any?
              scope = scope.where("#{Member.table_name}.id IN (SELECT DISTINCT member_id FROM #{MemberRole.table_name} WHERE role_id IN (?))", role_ids)
            end
          end
          scope.active.visible.sorted
        else
          []
        end
      end

      def validate_custom_value(custom_value)
        if custom_value.customized.respond_to?(:project) && (project = custom_value.customized.project) && project.is_from_template
          users_ids             = project.members.map(&:user_id) # this does not query the database, we need the unsaved related records
          users_from_groups_ids = Group.where(id: users_ids).joins(:users).pluck(:user_id)
          possible_values       = (users_ids | users_from_groups_ids).map(&:to_s)
        else
          possible_values = possible_custom_value_options(custom_value).map(&:last)
        end

        values         = Array.wrap(custom_value.value).reject { |value| value.to_s == '' }
        invalid_values = values - possible_values
        if invalid_values.any?
          [::I18n.t('activerecord.errors.messages.inclusion')]
        else
          []
        end
      end

    end

    module ClassMethods
    end

  end
end
