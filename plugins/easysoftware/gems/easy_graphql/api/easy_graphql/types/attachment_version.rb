# frozen_string_literal: true

module EasyGraphql
  module Types
    class AttachmentVersion < Base
      description 'AttachmentVersion'

      field :id, ID, null: false
      field :attachment, Types::Attachment, null: true
      field :filename, String, null: false
      field :filesize, String, null: false
      field :content_type, String, null: false
      field :description, String, null: true
      field :author, Types::User, null: true
      field :content_url, String, null: true
      field :attachment_path, String, null: true
      field :thumbnail_path, String, null: true
      field :version, String, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true

      field :editable, Boolean, null: false
      field :deletable, Boolean, null: false

      def content_url
        Rails.application.routes.url_helpers.download_named_attachment_path(object, object.filename, version: true)
      end

      def attachment_path
        options = IssuesController.helpers.url_to_attachment(object)
        Rails.application.routes.url_helpers.attachment_path(options)
      end

      def thumbnail_path
        if object.thumbnailable?
          Rails.application.routes.url_helpers.thumbnail_path(object)
        end
      end

      def editable
        object.editable?
      end

      def deletable
        object.deletable?
      end

    end
  end
end
