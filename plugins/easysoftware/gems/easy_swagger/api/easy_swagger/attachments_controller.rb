module EasySwagger
  class AttachmentsController

    include EasySwagger::BaseController
    swagger_me

    remove_action action: :get
    remove_action action: :post
    remove_action path: "#{base_path}/{id}.{format}", action: :put

    add_tag name: tag_name, description: "Attachment API"

    base = self

    add_action "/uploads.{format}" do
      operation :post do
        key :summary, "Upload file to server"
        key :tags, [base.tag_name]
        request_body do
          key :description, "Request body is the file content"
          key :required, true
          content "application/octet-stream" do
            schema do
              key :type, "string"
              key :format, "binary"
            end
          end
        end

        extend EasySwagger::Parameters
        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity

        response 201 do
          key :description, "created"
          EasySwagger.formats.each do |format|
            content format do
              schema do
                if format.include?('json')
                  key :type, "object"
                  property "upload" do
                    key "$ref", 'UploadResponse'
                  end
                else
                  key "$ref", 'UploadResponse'
                end
              end
            end
          end
        end
      end
    end

    add_action "/attach.{format}" do
      operation :post do
        key :summary, "Attach file to entity"
        key :tags, [base.tag_name]
        request_body do
          key :required, true
          key :description, "entity_type and entity_id correspond with entity the attachment will be attached to"
          EasySwagger.formats.each do |format|
            content format do
              schema do
                if format.include?('json')
                  key :type, "object"
                  property "attach" do
                    key "$ref", 'AttachRequest'
                  end
                else
                  key "$ref", 'AttachRequest'
                end
              end
            end
          end
        end

        extend EasySwagger::Parameters
        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 200, description: "ok"
      end
    end

  end
end
