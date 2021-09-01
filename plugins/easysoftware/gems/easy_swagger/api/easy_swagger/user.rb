module EasySwagger
  # describe User model
  class User

    module I18n

      include Redmine::I18n

    end

    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "easy_external_id", if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) } do
        key :example, "external-system-1"
      end
      property "login", if: ->(_context, user) { ::User.current.easy_lesser_admin_for?(:users) || (::User.current == user) } do
        key :example, "admin"
      end
      property "firstname" do
        key :example, "Filip"
      end
      property "lastname" do
        key :example, "Moravek"
      end
      property "mail", format: "email", if: ->(_context, user) { ::User.current.easy_lesser_admin_for?(:users) || !user.pref.hide_mail } do
        key :example, "ceo@easy.cz"
      end
      property "status", type: "integer", if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) } do
        key :example, 1
        key :enum, ::User.valid_statuses
      end
      property "easy_system_flag", type: "boolean", if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) } do
        key :description, "used for special operations, not human user"
      end
      property "easy_lesser_admin", type: "boolean", if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) } do
        key :description, "Partial administrator"
      end
      property "language" do
        #   key :enum, I18n.languages_options
      end

      property "admin", if: ->(_context, user) { ::User.current.easy_lesser_admin_for?(:users) || (::User.current == user) } do
        key :type, "boolean"
        key :description, "Is user Administrator?"
      end

      relation *%w[easy_user_type supervisor_user], if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) }

      custom_fields
    end

    request_schema do
      key :required, %w[firstname lastname mail password password_confirmation]
      property "login", if: ->(_context, _user) { ::User.current.admin? } do
        key :example, "filip"
        key :description, "only for creation, can't be changed"
      end
      property "password", format: "password"
      property "password_confirmation", format: "password"

      property "group_ids", type: "array" do
        key :description, "Assign user to given groups. Expect array of IDs"
        items do
          key :type, "integer"
        end
      end
      property "auth_source_id", type: "integer" do
        key :description, "ID of LDAP auth. source"
      end
    end

    response_schema do
      property "utc_offset" do
        key :type, "integer"
        key :example, 3600
        key :description, "Time zone offset in seconds"
        key :readOnly, true
      end
      property "last_login_on", type: "string", format: "date-time"
      property "avatar_url", type: "string", format: "uri"

      property "working_time_calendar", type: "object", if: ->(_context, user) { user.working_time_calendar } do
        key :readOnly, true
        property "id", type: "integer"
        property "name", type: "string"
        property "default_working_hours", type: "number" do
          key :format, "float"
          key :example, "8.0"
        end
        property "time_from", type: "string" do
          key :description, "Time when work start"
          key :example, "09:00"
        end
        property "time_to", type: "string" do
          key :description, "Time when work end"
          key :example, "17:00"
        end
      end

      property "groups", if: ->(_context, _user) { ::User.current.easy_lesser_admin_for?(:users) } do
        key :type, "array"
        key :description, "if you specify `include=groups`"
        key :readOnly, true
        items do
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

      timestamps legacy: true
    end
  end
end
