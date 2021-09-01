module EasyCrm
  module EasyContactsEntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_easy_contact_attribute, :easy_crm

      end
    end

    module InstanceMethods

      def format_html_easy_contact_attribute_with_easy_crm(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :avatar_column
          easy_contact = options.dup[:entity]
          avatar = easy_contact.easy_avatar ? avatar(easy_contact, :style => :large) : content_tag(:span, '', :class => 'easy-contact-default-avatar icon-' + (easy_contact.person? ? 'user' : 'home'))
          avatar
        when :easy_crm_cases
          render(:partial => 'easy_crm_contacts/easy_crm_contact_query_crm_cases', :locals => {:easy_crm_cases => unformatted_value, :easy_contact => options[:entity]})
        else
          format_html_easy_contact_attribute_without_easy_crm(entity_class, attribute, unformatted_value, options)
        end

      end

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyCrm::EasyContactsEntityAttributeHelperPatch', :last => true, :if => Proc.new{Redmine::Plugin.installed?(:easy_contacts)}
