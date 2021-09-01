module EasySwagger
  class ErrorModel
    include ::Swagger::Blocks

    swagger_component do
      schema "ErrorModel" do
        key :required, %w[attribute messages]
        property "attribute" do
          key :type, "string"
          key :example, "login"
        end
        property "messages" do
          key :type, "array"
          items do
            key :type, "string"
            key :example, "cannot be blank"
          end
        end
      end
    end
  end
end
