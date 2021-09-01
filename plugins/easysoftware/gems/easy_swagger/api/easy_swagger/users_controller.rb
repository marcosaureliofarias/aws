module EasySwagger
  class UsersController

    include EasySwagger::BaseController
    swagger_me

    add_tag name: tag_name, description: "Users API"
    add_includes groups: "groups which user is in", memberships: "list of projects which is user in role"
  end
end