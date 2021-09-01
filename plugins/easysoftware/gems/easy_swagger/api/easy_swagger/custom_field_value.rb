module EasySwagger
  class CustomFieldValue
    include EasySwagger::BaseModel
    swagger_me

    request_schema do
      key :required, %w[id value]
      property "id" do
        key :type, "integer"
        key :example, 1
      end
      property "value" do
        key :example, "Iron Man"
        key :description, "value is based on field_format - can be Array, Boolean, Date"
      end
    end

    response_schema do
      property "name" do
        key :example, "Hero list"
        key :readOnly, true
      end
      property "internal_name" do
        key :example, "easy_hero_list"
        key :readOnly, true
      end
      property "field_format" do
        key :readOnly, true
        key :enum, Redmine::FieldFormat.available_formats
      end
      property "value" do
        key :description, "value is based on field_format - can be Array, Boolean, Date"
      end
    end
  end
end