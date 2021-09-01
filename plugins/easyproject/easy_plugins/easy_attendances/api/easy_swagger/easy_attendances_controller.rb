module EasySwagger
  class EasyAttendancesController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Easy Attendances API"
  end
end