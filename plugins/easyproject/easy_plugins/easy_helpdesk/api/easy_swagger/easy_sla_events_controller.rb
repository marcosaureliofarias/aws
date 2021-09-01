module EasySwagger
  class EasySlaEventsController
    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "EasySlaEvents API"

    remove_action action: :get
    remove_action path: "#{base_path}/{id}.{format}", action: :get
    remove_action path: "#{base_path}/{id}.{format}", action: :put
    remove_action action: :post
  end
end
