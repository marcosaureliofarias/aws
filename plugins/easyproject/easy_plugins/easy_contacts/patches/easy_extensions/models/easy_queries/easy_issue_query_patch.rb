module EasyContactPatch
  module EasyIssueQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_contacts
        alias_method_chain :initialize_available_columns, :easy_contacts

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_contacts
        initialize_available_filters_without_easy_contacts

        group = l(:label_filter_group_easy_contact_query)
        add_available_filter 'easy_contacts.firstname', { type: :text, order: 1, group: group, name: l(:field_firstname), includes: :easy_contacts }
        add_available_filter 'easy_contacts.lastname', { type: :text, order: 2, group: group, name: l(:field_lastname), includes: :easy_contacts }
        add_principal_autocomplete_filter 'easy_contacts.assigned_to_id', { group: group, name: EasyContact.human_attribute_name(:account_manager), permitted: EasyContact.assigned_to_id_field_visible?, includes: :easy_contacts, klass: User }
        if EasyUserType.easy_type_partner.any?
          add_principal_autocomplete_filter 'easy_contacts.external_assigned_to_id', { group: group, name: EasyContact.human_attribute_name(:external_account_manager), permitted: EasyContact.external_assigned_to_id_field_visible?, includes: :easy_contacts, klass: User }
        end

        add_custom_fields_filters(EasyContactCustomField, :easy_contacts)
      end

      def initialize_available_columns_with_easy_contacts
        initialize_available_columns_without_easy_contacts

        add_associated_columns EasyContactQuery, association_name: :easy_contacts, groupable: :contact_name
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyContactPatch::EasyIssueQueryPatch'

