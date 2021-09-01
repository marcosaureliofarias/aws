module EasySwagger
  class EasyDocumentsController
    include EasySwagger::BaseController
    swagger_me entity: "Document"

    remove_action action: :get
    remove_action action: :post

    base = self
    add_action '/documents.{format}' do
      operation :get do
        key :summary, "Retrieve documents"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters
        extend EasySwagger::Responses::Basics
        
        response 200 do
          key :description, "ok"
          EasySwagger.formats.each do |format|
            content format do
              schema type: 'object' do
                property "documents", type: 'array' do
                  items do
                    key "$ref", base.api_response_entity_name
                  end
                end
              end
            end
          end
        end

      end
    end

  end
end