module EasySwagger
  class Document
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property 'title' do
        key :example, ''
      end
      property 'description' do
        key :example, ''
      end
      relation *%w[project category]
      custom_fields
    end

    request_schema do
      key :required, %w[title project_id category_id]
    end

    response_schema do
      attachments
      property 'created_on' do
        key :type, "string"
        key :format, "date-time"
        key :readOnly, true
      end
    end
  end
end
