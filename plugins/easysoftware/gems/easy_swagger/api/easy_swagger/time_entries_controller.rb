module EasySwagger
  class TimeEntriesController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Spent time API"

  end
end
