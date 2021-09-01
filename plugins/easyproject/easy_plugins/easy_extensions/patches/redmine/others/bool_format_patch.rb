module EasyPatch
  module BoolFormatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        self.type_for_inline_edit = 'select'
        alias_method_chain :single_check_box_edit_tag, :easy_extensions
      end
    end

    module InstanceMethods

      def single_check_box_edit_tag_with_easy_extensions(view, tag_id, tag_name, custom_value, options = {})
        s = ''.html_safe
        s << view.hidden_field_tag(tag_name, '0', id: nil) unless options[:no_hidden_field]
        s << view.check_box_tag(tag_name, '1', custom_value.value.to_s == '1', id: tag_id)
        view.content_tag('span', s, options)
      end

      def source_values_for_inline_edit(custom_field_value)
        possible_values_options(custom_field_value.custom_field).map do |possible_value|
          { text: possible_value.first, value: possible_value.last }
        end
      end

    end

  end
end
