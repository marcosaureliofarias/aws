require 'rys'

require 'easy_swagger/version'
require 'easy_swagger/engine'
require 'easy_swagger/utility'

require 'easy_api'
require 'swagger/blocks'

module EasySwagger

  autoload :ErrorModel, 'easy_swagger/error_model'
  autoload :HashBuilder, 'easy_swagger/hash_builder'
  autoload :JsonBuilder, 'easy_swagger/json_builder'
  autoload :Parameters, 'easy_swagger/parameters'
  autoload :Responses, 'easy_swagger/responses'

  # Configuration of Swagger
  #
  # @example Direct configuration
  #   Swagger.config.my_key = 1
  #
  # @example Configuration via block
  #   Swagger.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   Swagger.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for Swagger'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

  def self.built_in_classes
    %w[EasySwagger::ErrorModel]
  end

  def self.formats
    %w[application/json application/xml]
  end

  configure do |c|
    c.class_names_store = built_in_classes
  end

  # @param [Array] names
  def self.register(*names)
    EasySwagger.config.class_names_store.concat names
  end

  # @return [Array] of constantize classes
  def self.registered_classes
    EasySwagger.config.class_names_store.uniq.map(&:constantize)
  end

  # @return [String] YAML format of OpenAPI 3.0
  def self.to_yaml
    prepare_documentation.deep_stringify_keys.to_yaml
  end

  # Alias for .to_yaml
  def self.to_yml
    to_yaml
  end

  # @return [String] JSON format of OpenAPI 3.0
  def self.to_json
    prepare_documentation
  end

  def self.prepare_documentation
    node = ApiDocsController.send(:_swagger_nodes)
    node[:root_node].data[:tags].sort_by! { |i| i.data[:name].to_s }
    ::Swagger::Blocks.build_root_json(ApiDocsController.for_documentation)
  end

end
