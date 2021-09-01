class DummyEntitySwaggerSpec
  include EasySwagger::BaseModel
  swagger_me

  shared_scheme do
    property "easy_external_id", if: proc { User.current.id == 0 } do
      key :example, "external-system-1"
    end
    relation "author"

    property "list" do
      key :type, "array"
      key :description, "some list"
      items do
        key :type, "string"
      end
      key :example, %w[list1]
    end
  end

  request_schema do
    key :required, %w[author_id]
  end

  response_schema do
    timestamps
  end

end

shared_context "DummyEntitySwaggerSpec" do
  let(:entity) do
    double("DummyEntitySwaggerSpec",
           class: DummyEntitySwaggerSpec,
           id: 1,
           easy_external_id: "x1",
           author_id: User.current.id,
           author: User.current,
           list: ["cecek"],
           created_at: Time.current,
           updated_at: Time.current
    )
  end
end
