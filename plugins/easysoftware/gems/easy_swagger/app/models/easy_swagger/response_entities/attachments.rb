module EasySwagger
  module ResponseEntities
    # Redmine::Acts::Attachable options for response
    module Attachments
      include EasySwagger::ResponseEntities::Utility

      # @param [Hash] options
      # @option options [Proc] :if
      # @option options [Proc] :value
      def attachments(**options)
        property "attachments", extend_options_for('attachments', **options) do
          key :type, "array"
          key :description, "if you specify `include=attachments`"
          key :xml, wrapped: true
          items do
            key "$ref", 'Attachment'
          end
        end
      end
    end
  end
end
