module EasySwagger
  module BaseModel
    extend ActiveSupport::Concern

    class_methods do

      def entity_name
        entity.underscore
      end

      def entity
        @entity
      end

      # @param [String] entity is singular name of described model
      def swagger_me(entity: name.demodulize)
        @entity = entity
        ::EasySwagger.register name
        include GeneralDefinitions
      end

      # Store properties which are shared between request and response
      def shared_scheme(&block)
        @shared_scheme ||= block
      end

      def response_schema_name
        @response_schema_name || "#{entity}ApiResponse"
      end

      def request_schema_name
        @request_schema_name || "#{entity}ApiRequest"
      end

      # Response from server
      # @note describe response model - what Easy server return
      #   block can be optional - method is use for api description
      # @return EasySwagger::Blocks::SchemaNode
      def response_schema(name = nil, &block)
        model_name = @response_schema_name = name || response_schema_name

        easy_swagger_schema model_name do
          property "id", type: "integer", readOnly: true, example: 1
        end
        easy_swagger_schema model_name, &shared_scheme if shared_scheme && @shared_scheme_applied_to_response.nil?
        @shared_scheme_applied_to_response = true
        easy_swagger_schema model_name, &block

        component_with_schema model_name, &block
      end

      # Request to server
      # @note describe how request payload should look like
      # @return Swagger::Blocks::Nodes::ComponentNode
      def request_schema(name = nil, &block)
        model_name = @request_schema_name = name || request_schema_name

        easy_swagger_schema model_name, &shared_scheme if shared_scheme && @shared_scheme_applied_to_request.nil?
        @shared_scheme_applied_to_request = true
        easy_swagger_schema model_name, &block

        component_with_schema model_name, &block
      end

      def component_with_schema(model_name, &block)
        @component ||= swagger_component
        @component.data[:schemas] ||= {}
        @component.data[:schemas][model_name] = easy_swagger_schema model_name
        @component.schema model_name, &block if block_given?
        # try to display more-correct name in XML response
        base_entity_name = entity_name
        @component.data[:schemas][model_name].xml do
          key :name, base_entity_name
        end
        @component.data[:schemas][model_name]
      end

      def easy_swagger_schema(name, &block)
        @easy_swagger_schema_node_map ||= {}

        schema_node = @easy_swagger_schema_node_map[name]
        if schema_node
          # Merge this schema_node declaration into the previous one
          schema_node.instance_eval(&block) if block_given?
          schema_node
        else
          # First time we've seen this schema_node
          @easy_swagger_schema_node_map[name] = EasySwagger::Blocks::SchemaNode.call(version: '3.0.0', &block)
          @easy_swagger_schema_node_map[name].schema_name = name
          @easy_swagger_schema_node_map[name]
        end
      end

      # Build API in Redmine builder based on Swagger specs
      # @param [ActiveRecord] model_instance ActiveRecord model
      # @param [helper] context view_context
      # @param [Redmine::Views::Builders::Structure] api
      # @param [String] response_schema name of response model - by default "#{model}ApiResponse"
      # @param [String] root_name (self.entity_name) root element name
      # @param [Symbol] hook_method name of method used for hook
      # @example EasySwagger::EasyServer.render_api(easy_server, self, local_assigns[:api])
      def render_api(model_instance, context, api, response_schema: nil, root_name: self.entity_name, hook_method: nil)
        entity_class = model_instance.class.name
        scheme = nil
        # Legacy hooks did not use `entity` but underscored name of entity
        # @example easy_contact: easy_contact
        hook_locals = {
          model_instance.class.name.underscore.to_sym => model_instance,
          :entity => model_instance,
          :api => api
        }
        swagger_schema = proc do
          scheme = response_schema(response_schema || "#{entity_class}ApiResponse").to_api(model_instance, context, api)
          context.call_hook hook_method || :"helper_render_api_#{entity_class.underscore}", hook_locals
        end
        if root_name
          api.__send__ root_name, &swagger_schema
        else
          swagger_schema.call
        end

        scheme
      end

      # Render given object to json directly
      # @param [Object] object
      def to_json(object)
        context = EasyExtensions::ApiViewContext.get_context(format: :json) # Fake context :)
        builder = EasySwagger::JsonBuilder.new # Fake builder :)
        render_api(object, context, builder, response_schema: response_schema_name)
        builder.output
      end

      # @return Hash
      def to_h(object)
        context = EasyExtensions::ApiViewContext.get_context(format: :json) # Fake context :)
        builder = EasySwagger::HashBuilder.new # Fake builder :)
        render_api(object, context, builder, root_name: false, response_schema: response_schema_name)
        builder.output
      end

      #
      # @param [String] entity is singular name of described model
      # def swagger_me(entity: name.demodulize, &block) #(entity: name.demodulize)
      #   include GeneralDefinitions
      #
      #   self.entity = entity
      #   instance_eval(&block)
      #
      #   binding.pry
      #   ::EasySwagger.register name
      #
      #   general = @swagger_schema_node_map[name]
      #   read = @swagger_schema_node_map["read"]
      #   write = @swagger_schema_node_map["write"]
      #   r = general.dup
      #
      #
      # end

    end

    module GeneralDefinitions
      extend ActiveSupport::Concern
      included do
        include Swagger::Blocks

        base = self
      end

    end
  end
end
