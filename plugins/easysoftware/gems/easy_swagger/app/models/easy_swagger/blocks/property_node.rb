module EasySwagger
  module Blocks
    class PropertyNode < ::Swagger::Blocks::Nodes::PropertyNode

      # @return [Proc, Symbol]
      attr_accessor :if_condition
      # @return [String] name of this node
      attr_accessor :schema_name

      # @return [Proc]
      attr_writer :value
      # @param [ActiveRecord] object is an instance of any Entity
      # @param [helper] context view_context
      # @param [Redmine::Views::Builders::Structure] builder
      def to_api(object, context, builder)
        object_value = if @value
                         @value.call(context, object)
                       else
                         object.try(schema_name)
                       end
        return if object_value.nil?

        case data[:type]
        when "object"
          # in this case is `value` a relation.
          # @example easy_server.easy_data_center => value is a EasyDataCenter
          if data["$ref"]
            # TODO: If someone define another name, this guess should not work - we need some registerer with mapping
            swagger_spec = "::EasySwagger::#{object_value.class}".safe_constantize
            raise ArgumentError, "For #{object_value.class} could not find swagger spec class." unless swagger_spec

            swagger_spec.render_api(object_value, context, builder, root_name: schema_name)
          else
            builder.__send__ schema_name, properties.collect { |attribute, _| [attribute, object_value.try(attribute)] }.to_h
          end
        when "array"
          if @ref
            builder.array schema_name do
              object_value.each do |item|
                @ref.render_api(item, context, builder)
              end
            end
          elsif data[:items] && object_value.respond_to?(:each) && data[:items].data[:type] == 'object'
            #<entities type="array">
            #  <entity>
            #    <id>2237</id>
            #    <name>Name</name>
            #  </entity>
            #</entities>

            builder.array schema_name do
              array_properties = data[:items].properties
              item_schema = data[:items].schema_name || schema_name.singularize
              object_value.each do |item|
                builder.__send__ item_schema do
                  array_properties.each do |attribute, property|
                    property.to_api(item, context, builder)
                  end
                end

                #builder.__send__ item_schema, array_properties.map { |attribute, property| [attribute, item.try(attribute)] }.to_h # inline <entity id="1" type="EasyCrmCase" name="name"/>
              end
            end
          elsif object_value.present?
            builder.__send__ schema_name, object_value, type: :array
          end
        else
          builder.__send__ schema_name, object_value
        end

        builder
      end

      # @return [Hash]
      def properties
        data[:properties]&.data || {}
      end

      # Is allowed this node in API ?
      # @param [ActiveRecord] object is an instance of any Entity
      def allowed?(object, context)
        return true unless if_condition

        case if_condition
        when Proc
          if if_condition.arity == 2 # compatibility with conditions where only one (object) param
            if_condition.call context, object
          else
            if_condition.call object
          end
        when Symbol
          object.send if_condition
        end
      end

      def items(inline_keys = nil, &block)
        if inline_keys
          items_schema = inline_keys.delete(:schema_name)
          if (@ref = inline_keys.delete(:ref))
            inline_keys["$ref"] = @ref.response_schema_name
          end
        end
        items_node = ::EasySwagger::Blocks::ItemsNode.call(version: version, inline_keys: inline_keys, &block)
        items_node.schema_name = items_schema
        self.data[:items] = items_node
      end

      def value(&block)
        @value = block
      end

    end
  end
end
