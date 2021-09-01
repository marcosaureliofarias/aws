module EasySwagger
  class RolesController

    include EasySwagger::BaseController
    swagger_me

    remove_action action: :post
    remove_action path: "#{base_path}/{id}.{format}", action: :put
    remove_action path: "#{base_path}/{id}.{format}", action: :delete


    # base = self
    # add_action "{id}/roles/{user_id}.{format}" do
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