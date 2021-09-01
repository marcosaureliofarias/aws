module EasySwagger
  class DocumentsController

    include EasySwagger::BaseController
    swagger_me

    document_tag_name = add_tag name: tag_name, description: "Document object with all its details"
    project_documents_tag_name = add_tag name: "Project documents", description: "A list of Project Documents with all its details"

    base = self
    
    remove_action action: :get, path: '/documents.{format}'
    add_action '/projects/{project_id}/documents.{format}' do
      operation :get do
        key :summary, "Retrieve documents of the Project with specified id"
        key :tags, [document_tag_name, project_documents_tag_name]
        extend EasySwagger::Parameters
        parameter do
          key :name, "project_id"
          key :in, "path"
          key :description, "ID of Project"
          key :required, true
          schema type: "integer"
        end
        extend EasySwagger::Responses::Basics
        response 200 do
          key :description, "ok"
          EasySwagger.formats.each do |format|
            content format do
              schema type: 'object' do
                property 'groups', type: 'array' do
                  items do
                    key "$ref", 'DocumentsGroupApiResponse'
                  end
                end
              end
            end
          end
        end

      end
    end

    remove_action action: :post, path: '/documents.{format}'
    add_action '/projects/{project_id}/documents.{format}' do
      operation :post do
        key :summary, "Create a document in the Project with specified id"
        key :tags, [document_tag_name, project_documents_tag_name]
        extend EasySwagger::Parameters
        parameter do
          key :name, "project_id"
          key :in, "path"
          key :description, "ID of Project"
          key :required, true
          schema type: "integer"
        end

        request_body do
          key :description, "Create #{base.entity}"
          key :required, true
          content "application/json" do
            schema do
              key :type, "object"
              property base.entity.underscore do
                key "$ref", 'ProjectDocumentApiRequest'
              end
            end
          end
          content "application/xml" do
            schema do
              key "$ref", 'ProjectDocumentApiRequest'
            end
          end
        end
        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 201 do
          key :description, "created"
          content "application/json" do
            schema do
              key :type, "object"
              property base.entity.underscore do
                key "$ref", base.api_response_entity_name
              end
            end
          end
          content "application/xml" do
            schema do
              key "$ref", base.api_response_entity_name
            end
          end
        end
      end
    end

  end
end
