module EasyContacts
  module EasyPrintableTemplatePagesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :easy_printable_template_page_create_replacable_tokens_from_entity_project, :easy_contacts

        def easy_printable_template_page_create_replacable_tokens_from_entity_easy_contacts(easy_contact)
          tokens = {}
          tokens['contact_name'] = easy_contact.firstname
          tokens['contact_firstname'] = easy_contact.firstname
          tokens['contact_lastname'] = easy_contact.lastname

          easy_contact.visible_custom_field_values.each do |cf_value|
            tokens["easy_contact_cf_#{cf_value.custom_field.id}"] = show_value(cf_value)
          end

          tokens
        end

      end
    end

    module InstanceMethods

      def easy_printable_template_page_create_replacable_tokens_from_entity_project_with_easy_contacts(project)
        tokens = easy_printable_template_page_create_replacable_tokens_from_entity_project_without_easy_contacts(project)

        if project.module_enabled?(:easy_contacts)
          if first_contact = project.easy_contacts.first
            tokens.merge!(easy_printable_template_page_create_replacable_tokens_from_entity_easy_contacts(first_contact))
          end
        end

        tokens
      end

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EasyPrintableTemplatePagesHelper', 'EasyContacts::EasyPrintableTemplatePagesHelperPatch', if: proc { Redmine::Plugin.installed?(:easy_printable_templates) }
