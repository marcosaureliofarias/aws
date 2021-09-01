module EasyContactPatch
  module EasyInvoiceQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_columns, :easy_contacts
        alias_method_chain :initialize_available_filters, :easy_contacts
      end
    end

    module InstanceMethods

      def initialize_available_columns_with_easy_contacts
        initialize_available_columns_without_easy_contacts

        @available_columns.concat(EasyContactCustomField.visible.sorted.to_a.map { |cf| EasyQueryCustomFieldColumn.new(cf, assoc: :client, group: l(:label_easy_contact_client_custom_fields)) })
      end

      def initialize_available_filters_with_easy_contacts
        initialize_available_filters_without_easy_contacts

        add_custom_fields_filters(EasyContactCustomField, :client, dont_use_assoc_filter_name: true)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceQuery', 'EasyContactPatch::EasyInvoiceQueryPatch' , if: Proc.new { Redmine::Plugin.installed?(:easy_invoicing) }

