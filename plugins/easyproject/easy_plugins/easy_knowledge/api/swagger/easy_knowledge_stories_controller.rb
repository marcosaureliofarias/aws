module EasySwagger
  class EasyKnowledgeStoriesController
    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Knowledge posts API"

    base = self

    post = @swagger_path_node_map["#{base.base_path}.{format}".to_sym].data[:post]
    post.parameter do
      key :name, "project_id"
      key :description, "The ID of associated project if you want to associate any"
      key :in, "query"
      schema type: "integer"
    end
    post.parameter do
      key :name, "source_issue_id"
      key :description, "The ID of the source issue if there is any"
      key :in, "query"
      schema type: "integer"
    end

    put = @swagger_path_node_map["#{base.base_path}/{id}.{format}".to_sym].data[:put]
    put.data[:responses].delete 200
    put.response 204, description: "ok"

    add_action '/easy_knowledge_stories/{id}/add_to_favorite.{format}' do
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

    add_action '/easy_knowledge_stories/{id}/remove_from_favorite.{format}' do
      operation :post do
        key :summary, "Remove #{base.entity} from favorites"
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

    add_action '/easy_knowledge_stories/{id}/restore.{format}' do
      operation :get do
        key :summary, "Revert #{base.entity} to the specified version"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters

        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "ID of #{base.entity}"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "version_id"
          key :in, "query"
          key :description, "ID of the version (mutually exclusive with \"version\"; only one argument must be specified)"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "version"
          key :in, "query"
          key :description, "Number of the version (mutually exclusive with \"version_id\"; only one argument must be specified)"
          key :required, true
          schema type: "string"
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 204, description: "ok"
      end
    end

    add_action '/easy_knowledge_stories/{id}/update_category.{format}' do
      operation :post do
        key :summary, "Add or remove categories from #{base.entity}"
        key :tags, [base.tag_name]
        extend EasySwagger::Parameters

        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "ID of #{base.entity}"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "category_id"
          key :in, "query"
          key :description, "ID of category to be added or removed"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "add"
          key :in, "query"
          key :description, "set to 1 to add category (mutually exclusive with \"remove\")"
          key :required, true
          schema type: "string"
        end
        parameter do
          key :name, "remove"
          key :in, "query"
          key :description, "set to 1 to remove category (mutually exclusive with \"add\")"
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