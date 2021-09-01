module EasyApiDecorators
  class TimeEntry < EasyApiEntity

    include CustomFieldsHelper
    include TimelogHelper

    def build_api!(api)
      render_api_time_entry(api, @entity)
      api
    end

    def self.entity_class
      ::TimeEntry
    end
  end
end
