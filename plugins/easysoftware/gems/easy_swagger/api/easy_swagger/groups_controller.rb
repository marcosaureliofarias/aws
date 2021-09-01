module EasySwagger
  class GroupsController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Groups API"
    add_includes users: "users which are in group", memberships: "list of projects which is user in role"

    base = self
    add_action "{id}/users.{format}" do
      operation :post do
        key :summary, "Add User to #{base.entity}"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters
        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "ID of #{base.entity}"
          key :required, true
          schema type: "string"
        end
        request_body do
          key :description, "Update given #{base.entity}"
          key :required, true
          EasySwagger.formats.each do |format|
            content format do
              schema do
                property "user_ids" do
                  key :type, "array"
                  items do
                    key :type, "integer"
                  end
                end
              end
            end
          end
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 204, description: "ok"
      end
    end
    add_action "{id}/users/{user_id}.{format}" do
      operation :delete do
        key :summary, "Remove User from #{base.entity}"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters
        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "ID of #{base.entity}"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "user_id"
          key :in, "path"
          key :description, "ID of User"
          key :required, true
          schema type: "string"
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 204, description: "ok"
      end
    end
  end
end