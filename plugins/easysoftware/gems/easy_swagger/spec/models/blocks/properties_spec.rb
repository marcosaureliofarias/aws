RSpec.describe EasySwagger::Blocks::PropertiesNode do
  module DummySpecs
    class Child
      include ::EasySwagger::BaseModel
      swagger_me

      response_schema do

        property "guid" do
          key :format, "uuid"
          key :readOnly, true
          key :example, "4da1a894-7ad4-4f07-b261-d454036bd09f"
        end
      end
    end

    class Parent
      include ::EasySwagger::BaseModel
      swagger_me

      response_schema do
        ref "child", DummySpecs::Child.response_schema_name
      end
    end
  end

  it ".ref render property without siblings" do
    output = EasySwagger.to_json
    expect(output.dig(:components, :schemas, "ParentApiResponse", :properties)).to include("child" => { "$ref": "#/components/schemas/ChildApiResponse" })
    expect(output.dig(:components, :schemas, "ChildApiResponse", :properties, "guid")).to include(type: "string")
  end
end
