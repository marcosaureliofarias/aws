module EasySwagger
  module Blocks
    class ItemsNode < ::Swagger::Blocks::Nodes::ItemsNode

      attr_accessor :schema_name

      def property(name, inline_keys = nil, &block)
        self.data[:properties] ||= EasySwagger::Blocks::PropertiesNode.new
        super
      end

      # @return [Hash]
      def properties
        self.data[:properties]&.data || {}
      end
    end
  end

end