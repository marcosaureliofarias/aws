module EasySwagger
  class EasyCrmCase
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do

      property "name", type: "string" do
        key :example, 'test 2'
        key :description, "Name"
      end

      relation *%w[easy_crm_case_status assigned_to author project main_easy_contact external_assigned_to]

      property "description", type: "string" do
        key :example, '<p>xxxx</p>
'
        key :description, "Description"
      end

      # @todo: Delete this
      property "easy_crm_case_status_id", type: "integer" do
        key :example, '4'
        key :description, "Temporary backwards compatibility"
      end

      property "contract_date", type: "string" do
        key :example, '2020-05-15'
        key :format, "date"
        key :description, ""
      end

      property "email", type: "string" do
        key :example, 'lukas@easy.cz'
        key :format, "email"
        key :description, ""
      end

      property "telephone", type: "string" do
        key :description, ""
      end

      property "price", type: "number" do
        key :example, '130.0'
        key :description, "Price"
      end

      property "currency", type: "string" do
        key :example, 'EUR'
        key :description, "Currency"
      end

      property "need_reaction", type: "boolean" do
        key :description, ""
      end

      property "next_action", type: "string" do
        key :format, "date-time"
        key :description, ""
      end

      property "is_canceled", type: "boolean" do
        key :description, ""
      end

      property "is_finished", type: "boolean" do
        key :description, ""
      end

      property "lead_value", type: "integer" do
        key :description, ""
      end

      property "probability", type: "integer" do
        key :description, ""
      end

      property "email_cc", type: "string" do
        key :description, "Email cc"
        key :format, "email"
      end

      property "easy_external_id", type: "string" do
        key :description, ""
      end

      custom_fields
    end

    request_schema do
      # key :required, %w[project_id user_id hours spent_on]
    end

    response_schema do

      relation *%w[accounted_by easy_closed_by easy_last_updated_by]

      property "closed_on", type: "string" do
        key :example, '2020-05-15 14:16:07 UTC'
        key :format, "date-time"
        key :description, "Closed"
        key :readOnly, true
      end

      attachments
      journals value: ->(context, entity) { context&.instance_variable_get(:@journals) || entity.journals.non_system.to_a }

      property "watchers", if: ->(crm_case) { ::User.current.allowed_to?(:view_easy_crm_case_watchers, crm_case.project) } do
        key :type, "array"
        key :description, "if you specify `include=watchers`"
        key :xml, wrapped: true
        items do
          key :title, "Watcher"
          key :type, "object"
          key :readOnly, true
          property "user", type: "object" do
            property "id", type: "integer"
            property "name"
          end
        end
      end

      property "easy_crm_case_items", type: "array" do
        key :xml, wrapped: true
        items ref: ::EasySwagger::EasyCrmCaseItem
      end

      timestamps legacy: false
    end

  end
end