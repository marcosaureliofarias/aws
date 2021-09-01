module EasySwagger
  class CustomField
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do

      property "name", type: "string" do
        key :example, 'auta'
        key :description, "Name of custom field"
      end

      property "field_format", type: "string" do
        key :example, 'list'
        key :description, "Format"
        key :enum, Redmine::FieldFormat.all.keys
      end

      property "regexp", type: "string" do
        key :description, "Regular expression"
      end

      property "min_length", type: "integer" do
        key :description, "Minimum length"
      end

      property "max_length", type: "integer" do
        key :description, "Maximum length"
      end

      property "is_required", type: "boolean" do
        key :description, "Required"
      end

      property "is_for_all", type: "boolean" do
        key :description, "For all projects"
      end

      property "is_filter", type: "boolean" do
        key :description, "Used as a filter"
      end

      property "position", type: "integer" do
        key :example, 2
        key :description, "Position of custom field in list"
      end

      property "searchable", type: "boolean" do
        key :description, "is searchable ?"
      end

      property "default_value", type: "string" do
        key :description, "Default value"
      end

      property "editable", type: "boolean" do
        key :description, "Editable"
      end

      property "visible", type: "boolean" do
        key :description, "Visible"
      end

      property "multiple", type: "boolean" do
        key :description, "Multiple values"
      end

      property "description", type: "string" do
        key :description, "Description"
      end

      property "is_primary", type: "boolean" do
        key :description, "Primary"
      end

      property "show_empty", type: "boolean" do
        key :description, "Show with empty fields"
      end

      property "show_on_list", type: "boolean" do
        key :description, "Show in list"
      end

      property "settings", type: "string" do
        key :description, "Its Hash object"
      end

      property "internal_name", type: "string" do
        key :description, ""
      end

      property "show_on_more_form", type: "boolean" do
        key :example, 'true'
        key :description, "Show as additional attribute"
      end

      property "easy_external_id", type: "string" do
        key :description, ""
      end

      property "easy_min_value", type: "number" do
        key :format, "float"
        key :description, ""
      end

      property "easy_max_value", type: "number" do
        key :format, "float"
        key :description, ""
      end

      property "mail_notification", type: "boolean" do
        key :example, 'true'
        key :description, "Email notifications"
      end

      property "easy_group_id", type: "integer" do
        key :description, ""
      end

      property "clear_when_anonymize", type: "boolean" do
        key :description, "Clear when anonymize"
      end
    end

    request_schema do
      key :required, %w[name]

      property "possible_values", type: "string" do
        key :example, "BMW\nSkoda"
        key :description, "Possible values are separated by newline"
      end
    end

    response_schema do

      property "type", type: "string" do
        key :example, 'IssueCustomField'
        key :description, "Type"
        key :readOnly, true
      end

      property "possible_values", type: "array" do
        key :example, %w(BMW Skoda)
        key :description, "Possible values are separated by newline"
        items do
          key :type, "string"
        end
      end

      property "format_store", type: "string" do
        key :example, '{"url_pattern"=>"", "edit_tag_style"=>""}'
        key :description, ""
        key :readOnly, true
      end

      property "easy_computed_token", type: "string" do
        key :example, ''
        key :description, ""
        key :readOnly, true
      end

      property "non_deletable", type: "boolean" do
        key :example, 'false'
        key :description, ""
        key :readOnly, true
      end

      property "non_editable", type: "boolean" do
        key :example, 'false'
        key :description, ""
        key :readOnly, true
      end

      property "disabled", type: "boolean" do
        key :example, 'false'
        key :description, ""
        key :readOnly, true
      end
      timestamps legacy: false
    end

  end

end