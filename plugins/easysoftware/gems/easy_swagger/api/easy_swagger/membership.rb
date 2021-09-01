module EasySwagger
  class Membership
    include EasySwagger::BaseModel
    swagger_me

    request_schema do
      key :required, %w[role_ids user_ids]
      property "user_ids", type: "array" do
        key :description, "IDs of several users for batch creation. Ignored in PUT requests."
        items do
          key :type, "integer"
        end
      end
      property "role_ids", type: "array" do
        key :description, "IDs of roles"
        items do
          key :type, "integer"
        end
      end
    end

    response_schema do
      relation *%w[project user group]
      property "roles", if: ->(_context, group) { !group.builtin? } do
        key :type, "array"
        key :readOnly, true
        items do
          key :title, "Role"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name", type: "string"
          property "inherited", type: "boolean"
        end
      end

      timestamps
    end

  end
end