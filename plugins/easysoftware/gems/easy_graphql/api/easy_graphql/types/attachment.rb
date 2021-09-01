# frozen_string_literal: true

module EasyGraphql
  module Types
    class Attachment < Base
      description 'Attachment'

      has_custom_values

      field :id, ID, null: false
      field :filename, String, null: false
      field :filesize, String, null: false
      field :content_type, String, null: false
      field :description, String, null: false
      field :author, Types::User, null: true
      field :content_url, String, null: true
      field :attachment_path, String, null: true
      field :thumbnail_path, String, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true
      field :webdav_url, String, null: true
      field :version, String, null: true
      field :versions, [Types::AttachmentVersion], null: true
      field :easy_short_urls, [Types::EasyShortUrl], null: true

      field :editable, Boolean, null: false
      field :deletable, Boolean, null: false

      def content_url
        Rails.application.routes.url_helpers.download_named_attachment_path(object, object.filename)
      end

      def attachment_path
        attachment = object.current_version.new_record? ? object : object.current_version
        options = IssuesController.helpers.url_to_attachment(object)
        Rails.application.routes.url_helpers.attachment_path(options)
      end

      def thumbnail_path
        if object.thumbnailable?
          Rails.application.routes.url_helpers.thumbnail_path(object)
        end
      end

      def webdav_url
        if EasySetting.value('easy_webdav_enabled')
          # Webdav doesn't have classic routes so thats why
          "#{issue_controller.root_url}#{issue_controller.webdav_attachment_path(object)}"
        end
      end

      def editable
        object.editable?
      end

      def deletable
        object.deletable?
      end

      def easy_short_urls
        ::EasyShortUrl.where(entity: object).order(valid_to: :desc)
      end

    end
  end
end
