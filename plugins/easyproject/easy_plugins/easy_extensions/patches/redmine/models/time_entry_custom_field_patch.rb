module EasyPatch
  module TimeEntryCustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_and_belongs_to_many :activities, -> { where(:enumerations => { :type => 'TimeEntryActivity' }) }, :join_table => "#{table_name_prefix}custom_fields_enumerations#{table_name_suffix}", :foreign_key => 'custom_field_id', :class_name => 'TimeEntryActivity', :association_foreign_key => 'enumeration_id'

        safe_attributes 'activity_ids'

        def visible_by_activity?(activity, user = User.current)
          self.visible? || self.activity_ids.include?(activity.try(:id))
        end

        # todo http://www.redmine.org/issues/31859
        def visible_by?(project, user=User.current)
          super# || (roles & user.roles_for_project(project)).present?
        end

        def validate_custom_field
          super
          #errors.add(:base, l(:label_role_plural) + ' ' + l('activerecord.errors.messages.blank')) unless visible? || roles.present?
        end
      end
    end

    module InstanceMethods

      def validate_custom_value(custom_value)
        if !visible? && (!custom_value.customized || activities.exclude?(custom_value.customized.activity))
          value = custom_value.value
          errs  = []
          if value.is_a?(Array)
            if !multiple?
              errs << ::I18n.t('activerecord.errors.messages.invalid')
            end
          end
          errs.concat(format.validate_custom_value(custom_value))
          errs
        else
          super(custom_value)
        end
      end

      def visibility_by_project_condition(project_key = nil, user = User.current, id_column = nil)
        id_column ||= id
        if visible?
          "1=1"
        else
          "EXISTS(select 1 from custom_fields_enumerations where custom_field_id = #{id_column} and custom_fields_enumerations.enumeration_id = enumerations.id)"
        end
      end

    end

    module ClassMethods
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntryCustomField', 'EasyPatch::TimeEntryCustomFieldPatch'
