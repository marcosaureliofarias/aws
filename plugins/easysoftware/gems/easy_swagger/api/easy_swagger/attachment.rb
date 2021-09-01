module EasySwagger
  class Attachment
    include EasySwagger::BaseModel
    swagger_me

    response_schema "Attachment" do
      property "filename" do
        key :example, "service-agreement.odt"
      end
      property "filesize", type: "integer" do
        key :example, "451564"
      end
      property "content_type", example: "application/vnd.oasis.opendocument.text"
      property "content_url" do
        key :format, "uri"
        # key :example, Rails.application.routes.url_helpers.download_named_attachment_url(1, "service-agreement.odt", Mailer.default_url_options)
      end
      property "description"
      property "href_url" do
        key :format, "uri"
        # key :example, Rails.application.routes.url_helpers.named_attachment_url(1, "service-agreement.odt", Mailer.default_url_options)
      end
      property "thumbnail_url" do
        key :description, "if attachment is a thumbnailable? (its image?)"
        key :format, "uri"
      end
      property "author" do
        key :title, "User"
        key :type, "object"
        property "id", type: "integer"
        property "name"
      end
      property "created_on", format: "date-time"
    end

    response_schema "AttachmentApiResponse" do
      key "$ref", 'Attachment'
    end

    response_schema "UploadResponse" do
      property "id", type: "integer"
      property "token", type: "string"
    end
    @component.data[:schemas]['UploadResponse'].xml do
      key :name, 'upload'
    end

    request_schema "AttachRequest" do
      key :required, %w[entity_type entity_id]
      property "entity_type" do
        key :type, "string"
        key :example, "Issue"
      end
      property "entity_id", type: "integer"
      property "attachments", type: "array" do
        key :description, "Array of attachment tokens"
        key :xml, wrapped: true
        items do
          key :title, "attachment"
          key :type, "object"
          key :xml, name: "attachment"
          property "token", type: "string"
        end
      end
    end
    @component.data[:schemas]['AttachRequest'].xml do
      key :name, 'attach'
    end

  end
end