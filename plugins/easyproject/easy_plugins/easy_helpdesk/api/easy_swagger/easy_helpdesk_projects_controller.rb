module EasySwagger
  class EasyHelpdeskProjectsController
    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "EasyHelpdeskProjects API"

    remove_action action: :get
    remove_action action: :post
    remove_action path: "#{base_path}/{id}.{format}", action: :get
    remove_action path: "#{base_path}/{id}.{format}", action: :put
    remove_action path: "#{base_path}/{id}.{format}", action: :delete

    base = self
    add_action "find_by_email.{format}" do
      operation :get do
        key :summary, "Get the first helpdesk project by email parameters"
        key :tags, [base.tag_name]

        extend EasySwagger::Parameters
        parameter do
          key :name, "subject"
          key :in, "path"
          key :description, "Email subject"
          key :required, false
          schema type: "string"
        end

        parameter do
          key :name, "from"
          key :in, "path"
          key :description, "Email from"
          key :required, false
          schema type: "string"
        end

        parameter do
          key :name, "to"
          key :in, "path"
          key :description, "Email to"
          key :required, false
          schema type: "string"
        end

        parameter do
          key :name, "mailbox_username"
          key :in, "path"
          key :description, "Mailbox username"
          key :required, false
          schema type: "string"
        end

        extend EasySwagger::Responses::Basics
        response 200, description: "ok" do
          EasySwagger.formats.each do |format|
            content format do
              schema type: "object" do
                property "easy_helpdesk_project", type: 'object' do
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
