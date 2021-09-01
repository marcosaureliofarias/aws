module EasySwagger
  module ApplicationHelper

    # Build API in Redmine builder based on Swagger specs
    # @param [ActiveRecord] entity ActiveRecord model
    # @param [Redmine::Views::Builders::Structure] api
    # @param [String] response_schema name of response model - by default "#{model}ApiResponse"
    def render_api_from_swagger(entity, api, response_schema: nil)
      model_klass_name = entity.class.name
      swagger_model = EasySwagger.config.class_names_store.find do |register|
        register =~ /#{model_klass_name}\z/
      end
      swaggered_class = swagger_model.constantize
      swaggered_class.render_api(entity, self, api, response_schema: response_schema)
    end

  end
end
