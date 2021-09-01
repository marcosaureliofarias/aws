module EasyPatch
  module RedmineFieldFormatBasePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :join_for_order_statement, :easy_extensions

        class_attribute :summable_supported
        self.summable_supported = false
        class_attribute :type_for_inline_edit
        self.type_for_inline_edit = 'text'
        class_attribute :numeric
        self.numeric = false
        class_attribute :autocomplete_supported
        self.autocomplete_supported = false

        def get_value_from_params(value)
          value.to_s
        end

        def custom_value_before_save(custom_value)
        end

        def custom_value_after_save(custom_value)
        end

        def target_class_from_custom_field(custom_field)
          target_class
        end

        def date?(_custom_field)
          false
        end

        def date_time?(_custom_field)
          false
        end

        def summable_sql(custom_field)
          group_statement(custom_field)
        end

        def formatted_with_inline_edit(view, custom_field_value, formatted_value, options = {})
          css_class = "formatted-custom-value"
          css_class << " cf-#{custom_field_value.custom_field.field_format.to_s.dasherize}"

          case options[:css_class]
          when String then
            css_class << " #{options[:css_class]}"
          when Array then
            css_class << " #{options[:css_class].join(' ')}"
          end

          if custom_field_value.inline_editable? && self.class.type_for_inline_edit.present?
            css_class << ' editable multieditable'
          end
          view.content_tag :span, formatted_value,
                           class: css_class, data: {
                  name:            field_name_for_custom_field_value(custom_field_value),
                  value:           custom_field_value.value.to_s,
                  type:            type_for_inline_edit_value(custom_field_value),
                  possible_values: possible_values_for_inline_edit(custom_field_value),
                  source:          source_values_for_inline_edit(custom_field_value)
              }.merge!(options[:data] || {})
        end

        def field_name_for_custom_field_value(custom_field_value)
          field_name = "#{custom_field_value.customized.class.name.underscore}[custom_field_values]"
          field_name << "[#{custom_field_value.custom_field.id}]"
          field_name
        end

        def possible_values_for_inline_edit(custom_field_value)
          custom_field_value.custom_field.possible_values.to_json
        end

        def source_values_for_inline_edit(custom_field_value)
          possible_values_options(custom_field_value.custom_field).map do |possible_value|
            { text: possible_value, value: possible_value }
          end
        end

        def type_for_inline_edit_value(custom_field_value)
          if self.class.type_for_inline_edit.respond_to?(:call)
            self.class.type_for_inline_edit.call(custom_field_value)
          else
            self.class.type_for_inline_edit
          end
        end

        def numeric(custom_field)
          self.class.numeric
        end

        def numeric?(custom_field)
          self.numeric(custom_field)
        end

      end
    end

    module InstanceMethods

      def join_for_order_statement_with_easy_extensions(custom_field, uniq = true, reference = nil)
        alias_name = join_alias(custom_field)
        reference  ||= "#{custom_field.class.customized_class.table_name}.id"

        result = "LEFT OUTER JOIN #{CustomValue.table_name} #{alias_name}" +
            " ON #{alias_name}.customized_type = '#{custom_field.class.customized_class.base_class.name}'" +
            " AND #{alias_name}.customized_id = #{reference}" +
            " AND #{alias_name}.custom_field_id = #{custom_field.id}" +
            " AND (#{custom_field.visibility_by_project_condition})" +
            " AND #{alias_name}.value <> ''"
        if uniq
          result += " AND #{alias_name}.id = (SELECT max(#{alias_name}_2.id) FROM #{CustomValue.table_name} #{alias_name}_2" +
              " WHERE #{alias_name}_2.customized_type = #{alias_name}.customized_type" +
              " AND #{alias_name}_2.customized_id = #{alias_name}.customized_id" +
              " AND #{alias_name}_2.custom_field_id = #{alias_name}.custom_field_id)"
        end
        result
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::Base', 'EasyPatch::RedmineFieldFormatBasePatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::List', 'EasyPatch::ListPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::BoolFormat', 'EasyPatch::BoolFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::DateFormat', 'EasyPatch::DateFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::ListFormat', 'EasyPatch::ListFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::TextFormat', 'EasyPatch::TextFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::IntFormat', 'EasyPatch::IntFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::StringFormat', 'EasyPatch::StringFormatPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::UserFormat', 'EasyPatch::UserFormatPatch'

module EasyPatch
  module RedmineFieldFormatNumericPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        self.summable_supported = true
        self.numeric            = true

      end
    end

    module InstanceMethods

    end

  end

  module RedmineFieldFormatAttachmentFormatPatch

    def self.included(base)
      base.class_eval do

        self.type_for_inline_edit = nil
        self.customized_class_names = ['Principal']

        def get_value_from_params(value)
          value
        end

        def edit_tag(view, tag_id, tag_name, custom_value, options = {})
          attachment = nil
          if custom_value.value.present?
            attachment = Attachment.find_by(id: custom_value.value)
          end

          fake_container = Struct.new(:saved_attachments, :unsaved_attachments)

          view.hidden_field_tag("#{tag_name}[blank]", "") +
              view.render(partial: 'attachments/form',
                          locals:  {
                              attachment_param:    tag_name,
                              multiple:            false,
                              description:         false,
                              only_one_file:       true,
                              container:           fake_container.new([attachment].compact, []),
                              filedrop:            false,
                              disable_image_paste: true,
                          })
        end


      end
    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::Numeric', 'EasyPatch::RedmineFieldFormatNumericPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::AttachmentFormat', 'EasyPatch::RedmineFieldFormatAttachmentFormatPatch'

module EasyPatch
  module RedmineFieldFormatFloatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :validate_single_value, :easy_extensions

        def summable_sql(custom_field)
          "CAST(CASE #{join_alias(custom_field)}.value WHEN '' THEN '0' ELSE #{join_alias(custom_field)}.value END AS decimal(30,3))"
        end

      end
    end

    module InstanceMethods

      def validate_single_value_with_easy_extensions(custom_field, value, customized = nil)
        # 2,5 => 2.5
        value.tr!(',', '.')
        validate_single_value_without_easy_extensions(custom_field, value, customized)
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::FloatFormat', 'EasyPatch::RedmineFieldFormatFloatPatch'

module EasyPatch
  module RedmineFieldFormatRecordListPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :join_for_order_statement, :easy_extensions

        self.customized_class_names = nil
        self.autocomplete_supported = true

        self.type_for_inline_edit = ->(custom_field_value) {
          custom_field_value.custom_field.multiple ? 'checklist' : 'select'
        }

        def source_values_for_inline_edit(custom_field_value)
          possible_values = possible_values_options(custom_field_value.custom_field, custom_field_value.customized)
          possible_values.unshift(['', nil]) unless custom_field_value.custom_field.multiple
          possible_values.map do |possible_value|
            { text: possible_value.first, value: possible_value.last }
          end
        end

      end
    end

    module InstanceMethods

      def join_for_order_statement_with_easy_extensions(custom_field, uniq = true, reference = nil)
        alias_name = join_alias(custom_field)
        reference  ||= "#{custom_field.class.customized_class.table_name}.id"

        result = "LEFT OUTER JOIN #{CustomValue.table_name} #{alias_name}" +
            " ON #{alias_name}.customized_type = '#{custom_field.class.customized_class.base_class.name}'" +
            " AND #{alias_name}.customized_id = #{reference}" +
            " AND #{alias_name}.custom_field_id = #{custom_field.id}" +
            " AND (#{custom_field.visibility_by_project_condition})" +
            " AND #{alias_name}.value <> ''"
        if uniq
          result += " AND #{alias_name}.id = (SELECT max(#{alias_name}_2.id) FROM #{CustomValue.table_name} #{alias_name}_2" +
              " WHERE #{alias_name}_2.customized_type = #{alias_name}.customized_type" +
              " AND #{alias_name}_2.customized_id = #{alias_name}.customized_id" +
              " AND #{alias_name}_2.custom_field_id = #{alias_name}.custom_field_id)"
        end
        result += " LEFT OUTER JOIN #{target_class.table_name} #{value_join_alias custom_field}" +
            " ON CAST(CASE #{alias_name}.value WHEN '' THEN '0' ELSE #{alias_name}.value END AS decimal(30,0)) = #{value_join_alias custom_field}.id"

        result
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::RecordList', 'EasyPatch::RedmineFieldFormatRecordListPatch'

module EasyPatch
  module RedmineFieldFormatListPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :query_filter_values, :easy_extensions
      end
    end

    module InstanceMethods

      def query_filter_values_with_easy_extensions(*args)
        values = query_filter_values_without_easy_extensions(*args)
        if target_class && target_class <= User && User.current.logged?
          values.unshift(["<< #{I18n.t(:label_me)} >>", 'me'])
        end
        values
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::List', 'EasyPatch::RedmineFieldFormatListPatch'
