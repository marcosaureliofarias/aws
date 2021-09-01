module EasyPatch
  module ListPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :select_edit_tag, :easy_extensions
      end
    end

    module InstanceMethods
      # https://www.redmine.org/issues/34068
      def select_edit_tag_with_easy_extensions(view, tag_id, tag_name, custom_value, options={})
        blank_option = ''.html_safe
        unless custom_value.custom_field.multiple?
          if custom_value.custom_field.is_required?
            unless custom_value.custom_field.default_value.present? && custom_value.customized.new_record?
              blank_option = view.content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
            end
          else
            blank_option = view.content_tag('option', '&nbsp;'.html_safe, :value => '')
          end
        end
        options_tags = blank_option + view.options_for_select(possible_custom_value_options(custom_value), custom_value.value)
        s = view.select_tag(tag_name, options_tags, options.merge(:id => tag_id, :multiple => custom_value.custom_field.multiple?))
        if custom_value.custom_field.multiple?
          s << view.hidden_field_tag(tag_name, '')
        end
        s
      end
    end
  end
end
