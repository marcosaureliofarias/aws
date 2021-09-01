module EasySwagger
  class EasyToDoListItem
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do

      property "name", type: "string" do
        key :example, 'weekly status update'
        key :description, "Name"
      end

      property "position", type: "integer" do
        key :example, '1'
      end

      property "is_done", type: "boolean"

      relation *%w[easy_to_do_list]

      property "entity_id", type: "integer" do
        key :example, '1'
      end

      property "entity_type", type: "string" do
        key :example, 'Issue'
      end
    end

    request_schema do
      key :required, %w[name position is_done easy_to_do_list_id]
    end

    response_schema do
      timestamps
    end

  end
end