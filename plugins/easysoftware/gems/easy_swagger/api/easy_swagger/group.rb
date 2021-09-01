module EasySwagger
  # describe User model
  class Group

    module I18n

      include Redmine::I18n

    end

    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "easy_external_id" do
        key :example, "external-system-1"
      end
      property "name" do
        key :example, "support"
      end
      property "easy_system_flag", type: "boolean" do
        key :description, "used for special operations, not human user"
      end

      custom_fields
    end

    request_schema do
      key :required, %w[name]
      property "user_ids" do
        key :description, "Array of User IDs which belongs to this group"
        key :type, "array"
        items do
          key :type, "integer"
        end
      end
    end

    response_schema do
      property "builtin", type: "boolean", if: ->(_context, group) { group.builtin_type } do
        key :description, "false if the group can be given to a user"
      end
      property "created_on" do
        key :type, "string"
        key :format, "date-time"
        key :readOnly, true
      end

      property "users", if: ->(_context, group) { !group.builtin? } do
        key :type, "array"
        key :description, "if you specify `include=users`"
        key :readOnly, true
        items do
          key :title, "User"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name", type: "string"
        end
      end

      property "memberships" do
        key :type, "array"
        key :description, "if you specify `include=memberships`"
        key :readOnly, true
        items do
          key :title, "Membership"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "project" do
            key :type, "object"
            property "id", type: "integer"
            property "name", type: "string"
          end
          property "roles" do
            key :type, "array"
            items do
              key :title, "Role"
              key :type, "object"
              property "id", type: "integer"
              property "name", type: "string"
              property "inherited", type: "boolean" do
                key :description, "only if inherited_from.present?"
              end
            end
          end
        end
      end
    end
  end
end