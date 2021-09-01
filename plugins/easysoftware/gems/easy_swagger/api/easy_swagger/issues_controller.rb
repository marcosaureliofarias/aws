module EasySwagger
  class IssuesController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Tasks API"
    add_includes_for_index attachments: "", relations: "", total_estimated_time: "", spent_time: ""
    add_includes_for_show children: "list of issue children", attachments: "", relations: "", changesets: "", journals: "", watchers: ""

    base = self

    add_action "/easy_issues/{id}/favorite.{format}" do
      operation :post do
        key :summary, "Add Issue to favorites"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters

        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "ID of #{base.entity}"
          key :required, true
          schema type: "string"
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 204, description: "ok"
      end
    end
  end
end