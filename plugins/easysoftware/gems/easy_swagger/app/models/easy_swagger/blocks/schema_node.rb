module EasySwagger
  module Blocks
    class SchemaNode < ::Swagger::Blocks::Nodes::SchemaNode

      # @return [String] name of schema
      attr_accessor :schema_name

      def property(name, inline_keys = nil, &block)
        data[:properties] ||= ::EasySwagger::Blocks::PropertiesNode.new
        super
        properties[name].data[:type] ||= "string"
      end

      # @param [String] name of node
      # @param [String] model name of OpenAPI model
      def ref(name, model)
        property name, "$ref": model
        properties[name].data.delete(:type)
      end

      def items(inline_keys = nil, &block)
        self.data[:items] = ::EasySwagger::Blocks::ItemsNode.call(version: version, inline_keys: inline_keys, &block)
      end

      def api_response?
        schema_name.to_s.end_with? "ApiResponse"
      end

      def custom_fields
        if api_response?
          custom_fields_response
        else
          custom_fields_request
        end
      end

      # Custom Fields list returned in server response
      def custom_fields_response
        data[:properties].custom_field_property do
          key :type, "array"
          key :xml, wrapped: true
          items do
            key :"$ref", "CustomFieldValueApiResponse"
          end
        end
      end

      # Custom Fields expected in request to server
      def custom_fields_request
        data[:properties].custom_field_property do
          key :type, "array"
          items do
            key :"$ref", "CustomFieldValueApiRequest"
          end
        end
      end

      # Relations in API - response contains object with `name` and `id`, request will be integer with +_id+ suffix
      # Always specify fields without `_id` suffix !
      # @example relation *%w[user project easy_data_center]
      def relation(*fields)
        inline_keys = fields.extract_options!
        if api_response?
          fields.each do |column|
            raise ArgumentError, "You specify relation with `_id` on the end." if column.end_with?("_id")

            property column, inline_keys do
              key :type, "object"
              key :readOnly, true
              property "id", type: "integer"
              property "name", type: "string"
            end
          end
        else
          fields.each do |column|
            property "#{column}_id", inline_keys do
              key :type, "integer"
            end
          end
        end
      end

      # @param [Boolean] legacy will use _on timestamps instead of _at
      def timestamps(legacy: false)
        stamps = legacy ? %w[created_on updated_on] : %w[created_at updated_at]
        stamps.each do |column|
          property column do
            key :type, "string"
            key :format, "date-time"
            key :readOnly, true
          end
        end
      end

      include EasySwagger::RedmineResponses

      # @param (see EasySwagger::Blocks::PropertyNode#to_api)
      def to_api(object, context, builder)
        properties.each do |_, node|
          next unless node.allowed?(object, context)

          node.to_api(object, context, builder)
        end
      end

      def properties
        data[:properties].data
      end

    end
  end
end
