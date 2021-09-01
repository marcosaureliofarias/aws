module EasySwagger
  class ProjectDocument
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property 'title' do
        key :example, ''
      end
      property 'description' do
        key :example, ''
      end
      relation *%w[category]
      custom_fields
    end

    request_schema do
      key :required, %w[title category_id]
      key :xml, name: 'document'
    end

    @component.data[:schemas][request_schema_name].xml do
      key :name, 'document'
    end
  end
end
