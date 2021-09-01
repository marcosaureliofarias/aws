module EasySwagger
  module Blocks
    class PropertiesNode < ::Swagger::Blocks::Nodes::PropertiesNode

      # @param (see Swagger::Blocks::Nodes::PropertiesNode#property)
      def property(name, inline_keys = nil, &block)
        if_condition = inline_keys.delete(:if) if inline_keys
        value_proc = inline_keys.delete(:value) if inline_keys
        data[name] = PropertyNode.call(version: version, inline_keys: inline_keys, &block)
        data[name].schema_name = name
        data[name].if_condition = if_condition
        data[name].value = value_proc
        data[name].data[:type] ||= "string"
      end

      # @param (see EasySwagger::Blocks::SchemaNode#ref)
      def ref(name, model)
        property name, "$ref": model
        data[name].data.delete(:type)
      end

      def custom_field_property(&block)
        data["custom_fields"] = CustomFieldPropertyNode.call(version: version, &block)
      end

      def properties
        data[:properties].data
      end

    end
  end
end
