module EasyApiDecorators
  class Project < EasyApiEntity

    include CustomFieldsHelper
    include ProjectsHelper

    def build_api!(api)
      render_api_project(api, @entity)
      api
    end

    def self.entity_class
      ::Project
    end
  end
end
