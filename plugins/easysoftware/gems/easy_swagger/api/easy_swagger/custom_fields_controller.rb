module EasySwagger
  class CustomFieldsController

    include EasySwagger::BaseController
    swagger_me

    # remove_action action: :get

    add_tag name: tag_name, description: "CustomField API"

    path_node(:"#{base_path}.{format}").data[:post].parameter do
      key :name, "type"
      key :description, "Name of custom field class"
      key :in, "query"
      schema do
        key :type, "string"
        key :example, "IssueCustomField"
        key :enum, CustomField.descendants.map(&:name).presence || %w[IssueCustomField ProjectCustomField UserCustomField]
      end
    end

    # base = self
    # add_action "{id}/custom_fields/{user_id}.{format}" do
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