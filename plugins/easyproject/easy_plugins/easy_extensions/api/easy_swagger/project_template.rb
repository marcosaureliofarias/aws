module EasySwagger
  class ProjectTemplate
    include EasySwagger::BaseModel
    swagger_me

    request_schema "CreateProjectTemplateRequest" do
      key :required, %w[id template]
      property "id", type: "string"

      property "template", type: "object" do
        property "assign_entity", type: "object" do
          property "type", type: "string"
          property "id", type: "string"
        end

        property "project", type: "array" do
          items do
            property "id", type: "integer"
            property "name", type: "string"
            property "custom_field_values", type: "object" do
              property type: "string"
            end

            property "project_custom_field_ids", type: "array" do
              items do
                key :type, "string"
              end
            end
          end
        end

        property "parent_id", type: "string"
        property "start_date", type: "string", format: "date"
        property "dates_settings", type: "string"
        property "change_issues_author", type: "string"
        property "inherit_time_entry_activities", type: "string"
      end

      property "notifications", type: "string"
    end

    request_schema "CopyProjectTemplateRequest" do
      key :required, %w[id template]
      property "id", type: "string"

      property "template", type: "object" do
        property "assign_entity", type: "object" do
          property "type", type: "string"
          property "id", type: "string"
        end

        property "target_root_project_id", type: "string"
        property "start_date", type: "string", format: "date"
        property "dates_settings", type: "string"
        property "change_issues_author", type: "string"
        property "inherit_time_entry_activities", type: "string"
      end

      property "notifications", type: "string"
    end
  end
end
