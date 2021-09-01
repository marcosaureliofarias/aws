module EasySwagger
  module ResponseEntities
    # ActsAsEasyJournalized options for response
    module Journals
      include EasySwagger::ResponseEntities::Utility

      # @param [Hash] options
      # @option options [Proc] :if
      # @option options [Proc] :value
      def journals(**options)
        property "journals", extend_options_for('journals', **options) do
          key :type, "array"
          key :description, "if you specify `include=journals`"
          key :xml, wrapped: true
          items ref: EasySwagger::Journal
        end
      end
    end
  end
end
