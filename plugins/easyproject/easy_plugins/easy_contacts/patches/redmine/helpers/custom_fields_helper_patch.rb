module EasyContacts
  module CustomFieldsHelperPatch

    def self.included(base)

      base.include(InstanceMethods)

      base.class_eval do
      end

    end

    module InstanceMethods

      def registration_no_custom_field_tag(custom_field, custom_value, field_name, field_id, options)
        content_tag(:span, custom_value.custom_field.format.edit_tag(
          self,
          field_id,
          field_name,
          custom_value,
          class: "#{custom_value.custom_field.field_format}_cf",
          data: { internal_name: custom_value.custom_field.internal_name }
        ) + link_to_function(
          content_tag(:span, t(:label_easy_contacts_reg_no_query), :class => 'tooltip'),
          "EASY.queryEasyContactsRegNo('#{easy_contacts_reg_no_query_path}', '[data-internal-name=#{custom_value.custom_field.internal_name}]')",
          class: 'search_link icon-adressbook'
        ), :class => 'input-append')
      end

      def vat_no_custom_field_tag(custom_field, custom_value, field_name, field_id, options)
        custom_value.custom_field.format.edit_tag(
          self,
          field_id,
          field_name,
          custom_value,
          class: "#{custom_value.custom_field.field_format}_cf",
          data: { internal_name: custom_value.custom_field.internal_name }
        )
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch('CustomFieldsHelper', 'EasyContacts::CustomFieldsHelperPatch')
