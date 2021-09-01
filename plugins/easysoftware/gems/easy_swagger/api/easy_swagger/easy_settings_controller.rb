module EasySwagger
  class EasySettingsController

    include EasySwagger::BaseController
    swagger_me entity: "EasySetting", base_path: "/admin/easy_settings", redmine_api_responses: false
    remove_action action: :get

    add_tag name: tag_name, description: "Manage EasySetting remotely"

    swagger_component do
      schema "EasySetting" do
        key :required, %w[id name]
        property "id" do
          key :type, "integer"
          key :format, "int64"
          key :example, 1
        end
        property "name" do
          key :type, "string"
          key :example, "secret_service_api_key"
        end
        property "value" do
          key :type, "string"
          key :example, "2b55fb3f0be9ff5b895f"
        end
        property "project_id" do
          key :type, "integer"
        end
      end
    end

  end
end