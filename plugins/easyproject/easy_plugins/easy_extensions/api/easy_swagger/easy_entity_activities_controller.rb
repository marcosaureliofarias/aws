module EasySwagger
  class EasyEntityActivitiesController

    include EasySwagger::BaseController
    swagger_me

    remove_action action: :get

    add_tag name: tag_name, description: "EasyEntityActivities API"
  end
end
