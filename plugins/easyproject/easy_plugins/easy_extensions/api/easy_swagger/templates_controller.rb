module EasySwagger
  class TemplatesController
    include EasySwagger::BaseController
    swagger_me entity: "ProjectTemplates", base_path: "/templates"

    add_tag name: tag_name, description: "ProjectTemplates API"

    remove_action action: :get
    remove_action action: :post
    remove_action path: "#{base_path}/{id}.{format}", action: :get
    remove_action path: "#{base_path}/{id}.{format}", action: :put

    base = self
    add_action "#{base_path}.{format}" do
      operation :get do
        key :summary, "Get all #{base.entity}"
        key :tags, [base.tag_name]

        extend EasySwagger::Parameters
        extend EasySwagger::Responses::Basics
        response 200, description: "ok" do
          EasySwagger.formats.each do |format|
            content format do
              schema type: "object" do
                key :xml, name: "projects"

                property "projects", type: "array" do
                  items do
                    key "$ref", ::EasySwagger::Project.response_schema_name
                  end
                end
              end
            end
          end
        end
      end
    end

    %w[add restore].each do |action|
      add_action "#{base_path}/{id}/#{action}.{format}" do
        operation :get do
          key :summary, "#{action.camelize} #{base.entity.singularize}"
          key :tags, [base.tag_name]

          description = ' template' if action == 'restore'

          extend EasySwagger::Parameters
          parameter do
            key :name, "id"
            key :in, "path"
            key :description, "Id of the project#{description}"
            key :required, true
            schema type: "string"
          end

          extend EasySwagger::Responses::Basics
          extend EasySwagger::Responses::UnprocessableEntity
          response 204, description: "ok"
        end
      end
    end

    add_action "#{base_path}/{id}/create.{format}" do
      operation :post do
        key :summary, "Create project from project template"
        key :tags, [base.tag_name]

        extend EasySwagger::Parameters
        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "Id of the source project template"
          key :required, true
          schema type: "string"
        end

        request_body do
          key :required, true
          key :description, "Create from project template parameters"
          EasySwagger.formats.each do |format|
            content format do
              schema do
                key "$ref", "CreateProjectTemplateRequest"
              end
            end
          end
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 201, description: "created" do
          EasySwagger.formats.each do |format|
            content format do
              schema do
                if format.include?('json')
                  key :type, "object"
                  property "project" do
                    key "$ref", ::EasySwagger::Project.response_schema_name
                  end
                else
                  key :xml, name: "project"
                  key "$ref", ::EasySwagger::Project.response_schema_name
                end
              end
            end
          end
        end
      end
    end

    add_action "#{base_path}/{id}/copy.{format}" do
      operation :post do
        key :summary, "Copy project template into existing project"
        key :tags, [base.tag_name]

        extend EasySwagger::Parameters
        parameter do
          key :name, "id"
          key :in, "path"
          key :description, "Id of the source project template"
          key :required, true
          schema type: "string"
        end

        request_body do
          key :required, true
          key :description, "Copy project template parameters"
          EasySwagger.formats.each do |format|
            content format do
              schema do
                key "$ref", "CopyProjectTemplateRequest"
              end
            end
          end
        end

        extend EasySwagger::Responses::Basics
        extend EasySwagger::Responses::UnprocessableEntity
        response 201, description: "created" do
          EasySwagger.formats.each do |format|
            content format do
              schema do
                if format.include?('json')
                  key :type, "object"
                  property "project" do
                    key "$ref", ::EasySwagger::Project.response_schema_name
                  end
                else
                  key :xml, name: "project"
                  key "$ref", ::EasySwagger::Project.response_schema_name
                end
              end
            end
          end
        end
      end
    end
  end
end
