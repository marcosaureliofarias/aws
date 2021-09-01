module EasyProjectAttachments
  module EasyDocumentQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_project_attachments
        alias_method_chain :initialize_available_columns, :easy_project_attachments

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_project_attachments
        initialize_available_filters_without_easy_project_attachments

        group = l(:label_filter_group_easy_attachment_query)
        add_available_filter 'attachments.container_type', {type: :list, values: [[l(:label_issue), 'Issue'], [l(:label_document), 'Document']], group: group, name: Attachment.human_attribute_name(:container_type), includes: :attachments, assoc: :attachments}
        add_available_filter 'attachments.filename', {type: :text, group: group, name: Attachment.human_attribute_name(:filename), includes: :attachments, assoc: :attachments}
        add_available_filter 'attachments.filesize', {type: :integer, group: group, name: Attachment.human_attribute_name(:filesize), includes: :attachments, assoc: :attachments}
        add_available_filter 'attachments.downloads', {type: :integer, group: group, name: Attachment.human_attribute_name(:downloads), includes: :attachments, assoc: :attachments}
        add_available_filter 'attachments.created_on', {type: :date_period, group: group, name: Attachment.human_attribute_name(:created_on), includes: :attachments, assoc: :attachments}

        add_custom_fields_filters(AttachmentCustomField, :attachments, dont_use_assoc_filter_name: true)
      end

      def initialize_available_columns_with_easy_project_attachments
        initialize_available_columns_without_easy_project_attachments

        add_associated_columns EasyProjectAttachmentQuery, association_name: :attachments
        @available_columns
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyDocumentQuery', 'EasyProjectAttachments::EasyDocumentQueryPatch'