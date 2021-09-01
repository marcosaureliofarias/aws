module EasyPatch
  module ListFormatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :edit_tag, :easy_extensions
        self.autocomplete_supported = true

        self.type_for_inline_edit = ->(custom_field_value) {
          custom_field_value.custom_field.multiple ? 'checklist' : 'select'
        }

      end
    end

    module InstanceMethods

      def source_values_for_inline_edit(custom_field_value)
        values = possible_values_options(custom_field_value.custom_field).map do |possible_value|
          v = Array.wrap(possible_value)
          { text: v.first, value: v.last }
        end

        include_blank = !custom_field_value.custom_field.multiple && custom_field_value.custom_field.edit_tag_style != 'autocomplete'
        values.unshift({ text: '', value: '' }) if include_blank
        values
      end

      def edit_tag_with_easy_extensions(view, tag_id, tag_name, custom_value, options = {})
        if custom_value.custom_field.edit_tag_style == 'autocomplete'
          view.autocomplete_field_tag(tag_name, possible_custom_value_options(custom_value), custom_value.value, { :id => tag_id }.merge(options))
        else
          edit_tag_without_easy_extensions(view, tag_id, tag_name, custom_value, options)
        end
      end

    end

  end
end
