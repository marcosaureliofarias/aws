module EasySwagger
  class DocumentsGroup
    include EasySwagger::BaseModel
    swagger_me

    response_schema 'DocumentsGroupApiResponse' do
      key :title, 'DocumentsGroup'
      property 'name', type: 'string' do
      end
      property 'documents', type: 'array' do
        items ref: EasySwagger::Document
      end
    end
  end
end