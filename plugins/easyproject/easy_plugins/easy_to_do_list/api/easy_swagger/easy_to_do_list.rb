module EasySwagger
  class EasyToDoList
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "name", type: "string" do
        key :example, 'todo'
        key :description, "Name"
      end

      property "position", type: "integer" do
        key :example, '1'
      end
    end

    request_schema do
      key :required, %w[name user_id position]
    end

    response_schema do
      #property "user", type: "object" do
      #  property "id", type: "integer"
      #  property "name"
      #end

      property "easy_to_do_list_items", type: "array" do
        items ref: EasySwagger::EasyToDoListItem
      end

      timestamps
    end
  end
end