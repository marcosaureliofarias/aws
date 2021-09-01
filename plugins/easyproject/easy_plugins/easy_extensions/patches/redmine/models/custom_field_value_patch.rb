module EasyPatch
  module CustomFieldValuePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # used when localizing value from the database
        attr_accessor :already_localized

        alias_method_chain :visible?, :easy_extensions
        alias_method_chain :editable?, :easy_extensions
        alias_method_chain :validate_value, :easy_extensions

        def value_for_params
          if custom_field.field_format == 'datetime' && !already_localized
            cast_value             = custom_field.cast_value(@value)
            self.already_localized = true
            @value                 = Time.zone.local_to_utc(cast_value).to_s(:db)
          else
            @value
          end
        end

        def cast_value(cf = nil)
          cf ||= self.custom_field
          cf.cast_value(self.value)
        end

        def reinitialize_value(i = 0)
          if self.custom_field && self.custom_field.field_format == 'autoincrement'
            autoincrementnumber = CustomValue.get_next_autoincrement(self.custom_field, self.customized) + i
            self.value          = CustomValue.format_autoincrement(self.custom_field, autoincrementnumber)
          end
        end

        def need_to_rewrite
          self.custom_field.field_format == 'autoincrement' ? false : true
        end

        def validate_value_with_custom_field_value
          if custom_field.field_format == 'autoincrement' && !autoincrement_number_valid?
            customized.errors.add(:base, custom_field.name + ' ' + ::I18n.t('activerecord.errors.messages.taken'), attributes: ["cf_#{custom_field.id}"])
          end
        end

        def autoincrement_number_valid?
          return false if self.value.blank?

          return true if CustomValue.where(:customized_type => self.customized.class.name).
              where(:customized_id => self.customized.id).
              where(:custom_field_id => self.custom_field.id).
              where(:value => self.value).count == 1

          settings = self.custom_field.settings || {}
          scope    = CustomValue.joins(:custom_field).where(["#{CustomValue.table_name}.custom_field_id = ?", self.custom_field.id]).
              where(["#{CustomField.table_name}.type = ?", self.custom_field.type])

          if self.custom_field.type == 'IssueCustomField' && (settings['per_project'] == '1' || settings['per_tracker'] == '1')
            scope = scope.joins("INNER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CustomValue.table_name}.customized_id")
            if settings['per_project'] == '1'
              scope = scope.where(["#{Issue.table_name}.project_id = ?", self.customized.project_id])
            end
            if settings['per_tracker'] == '1'
              scope = scope.where(["#{Issue.table_name}.tracker_id = ?", self.customized.tracker_id])
            end
          end

          scope = scope.where(["#{CustomValue.table_name}.value = ?", self.value])
          scope.count == 0
        end

        # editable tested on: custom_field, entity, workflow
        def inline_editable?
          return true unless customized.present? && customized.respond_to?(:editable?)
          editable? && (customized.editable? || project_custom_fields_editable?) && editable_value
        end

        def editable_value
          if customized.respond_to?(:editable_custom_field_values)
            customized.editable_custom_field_values.any? { |cfv| cfv.custom_field == custom_field }
          else
            true
          end
        end

        def project_custom_fields_editable?(user = User.current)
          return unless customized.is_a? Project
          user.allowed_to?(:edit_project_custom_fields, customized)
        end

        private :editable_value

      end
    end

    module InstanceMethods

      def visible_with_easy_extensions?
        if self.custom_field.field_format == 'easy_rating'
          User.current && User.current.admin?
        else
          visible_without_easy_extensions?
        end
      end

      def editable_with_easy_extensions?
        if self.custom_field.field_format == 'attachment'
          CustomValue.new.attachments_editable?
        else
          editable_without_easy_extensions?
        end
      end

      def validate_value_with_easy_extensions
        custom_field.validate_custom_value(self).each do |message|
          customized.errors.add(:base, custom_field.name + ' ' + message, attributes: ["cf_#{custom_field.id}"])
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomFieldValue', 'EasyPatch::CustomFieldValuePatch'
