module EasySwagger
  class ProjectsController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Projects API"
    add_includes trackers: "List of enabled trackers on project", issue_categories: "List of IssueCategories", enabled_modules: "List of enabled project modules"
    base = self
    %w[close reopen archive unarchive].each do |action|
      add_action "{id}/#{action}.{format}" do
        operation :post do
          key :summary, "#{action.camelize} #{base.entity}"
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

    add_action "{id}/favorite.{format}" do
      operation :post do
        key :summary, "Add #{base.entity} to favorites"
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