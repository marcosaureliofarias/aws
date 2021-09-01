module EasySwagger
  module Blocks
    class CustomFieldPropertyNode < PropertyNode

      # @param (see EasySwagger::Blocks::PropertyNode#to_api)
      def to_api(object, context, builder)
        context.render_api_custom_values object.visible_custom_field_values, builder
      end

    end
  end
end
