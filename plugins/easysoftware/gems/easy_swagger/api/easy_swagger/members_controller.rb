module EasySwagger
  class MembersController

    include EasySwagger::BaseController
    swagger_me entity: "Membership"

    member_tag_name = add_tag name: tag_name, description: "Membership object with all its details"
    membership_tag_name = add_tag name: "Project membership", description: "A list of Project Memberships with all its details"

    remove_action action: :get
    remove_action action: :post

    base = self
    add_action "/projects/{project_id}#{base_path}.{format}" do
      operation :get do
        key :summary, "Retrieve memberships of the Project with specified id"
        key :tags, [membership_tag_name, member_tag_name]
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
              schema type: "object" do
                property "total_count", type: "number" do
                  key :example, 75
                  key :xml, attribute: true
                end
                property "offset", type: "number" do
                  key :example, 0
                  key :xml, attribute: true
                end
                property "limit", type: "number" do
                  key :example, 25
                  key :xml, attribute: true
                end
                xml name: base.entity_name.pluralize, wrapped: true
                property base.entity_name.pluralize, type: "array" do
                  items do
                    key "$ref", base.api_response_entity_name
                  end
                end
              end
            end
          end
        end
      end

      operation :post do
        key :summary, "Create a membership in a Project with specified id"
        key :tags, [membership_tag_name, member_tag_name]
        extend EasySwagger::Parameters
        parameter do
          key :name, "project_id"
          key :in, "path"
          key :description, "ID of Project"
          key :required, true
          schema type: "integer"
        end
        request_body do
          key :description, "Create #{membership_tag_name}"
          key :required, true
          content "application/json" do
            schema type: "object" do
              key :title, "Membership"
              key :required, %w[role_ids user_ids]
              key :description, "Create membership on project for users in given roles"
              property base.entity.underscore do
                key "$ref", base.api_request_entity_name
              end
            end
          end

          content "application/xml" do
            schema do
              key :title, "Membership"
              key :required, %w[role_ids user_ids]
              key :description, "Create membership on project for users in given roles"
              key "$ref", base.api_request_entity_name
            end
          end

        end
        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 201 do
          key :description, "created"
          EasySwagger.formats.each do |format|
            content format do
              schema do
                key "$ref", base.api_response_entity_name
              end
            end
          end
        end
      end
    end
  end
end