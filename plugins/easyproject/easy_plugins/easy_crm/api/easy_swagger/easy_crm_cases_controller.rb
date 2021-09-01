module EasySwagger
  class EasyCrmCasesController

    include EasySwagger::BaseController
    swagger_me

    # remove_action action: :get

    add_tag name: tag_name, description: "Crm Case API"

    # base = self
    # add_action "{id}/easy_crm_cases/{user_id}.{format}" do
    #   operation :delete do
    #     key :summary, "Some summary #{base.entity}"
    #     key :tags, [base.entity_name]
    #     extend EasySwagger::Parameters
    #     parameter do
    #       key :name, "id"
    #       key :in, "path"
    #       key :description, "ID of #{base.entity}"
    #       key :required, true
    #       schema type: "string"
    #     end
    #     parameter do
    #       key :name, "user_id"
    #       key :in, "path"
    #       key :description, "ID of User"
    #       key :required, true
    #       schema type: "string"
    #     end
    #
    #     extend EasySwagger::Responses::Basics
    #     extend EasySwagger::Responses::UnprocessableEntity
    #     response 204, description: "ok"
    #   end
    # end

  end
end