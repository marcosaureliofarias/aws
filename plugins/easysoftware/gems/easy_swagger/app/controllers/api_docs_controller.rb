class ApiDocsController < ActionController::Base
  include ::Swagger::Blocks
  # https://github.com/fotinakis/swagger-blocks

  swagger_component do
    security_scheme "headerKey" do
      key :type, "apiKey"
      key :name, "X-Redmine-API-Key"
      key :in, "header"
    end
    security_scheme "key" do
      key :type, "apiKey"
      key :name, "key"
      key :in, "query"
    end
  end

  swagger_root openapi: "3.0.0" do
    info do
      key :version, EasySwagger::VERSION
      key :title, "#{EasyExtensions::EasyProjectSettings.app_name} API"
      key :description, 'https://app.swaggerhub.com/apis/easysoftware/EasySwagger'
      # key :termsOfService, 'http://helloreverb.com/terms/'
      contact do
        key :name, 'Lukas Pokorny'
        key :email, EasyExtensions::EasyProjectSettings.app_email
        key :url, "https://#{EasyExtensions::EasyProjectSettings.app_link}"
      end
      license do
        key :name, 'GPLv3'
      end
    end

    security do
      key :key, []
      key :headerKey, []
    end

  end

  def self.for_documentation
    classes = EasySwagger.registered_classes.sort_by(&:name)
    classes << self
    classes
  end

  def index
    respond_to do |format|
      format.html { render layout: false }
      format.yaml { render plain: EasySwagger.to_yaml }
      format.json { render json: EasySwagger.to_json }
    end
  end

end
