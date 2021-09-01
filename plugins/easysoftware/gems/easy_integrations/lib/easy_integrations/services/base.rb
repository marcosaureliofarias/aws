module EasyIntegrations
  module Services
    class Base
      include Rails.application.routes.url_helpers

      attr_reader :status, :return_value

      def initialize(easy_integration)
        @easy_integration = easy_integration
        @status = :idle
        @return_value = nil
      end

      def self.register(symbol, options = {})
        EasyIntegrations.register_service(symbol, self, options)
      end

      def self.default_url_options
        Mailer.default_url_options
      end

      def perform(entity_or_entities, action)
        return false unless before_perform(entity_or_entities, action)

        fire_on(entity_or_entities, action)
        after_perform(entity_or_entities, action)

        true
      end

      def validate_settings
      end

      protected

      def fire_on(entity_or_entities, action)
        if entity_or_entities.is_a?(Array)
          fire_on_entities(entity_or_entities, action)
        else
          fire_on_entity(entity_or_entities, action)
        end
      end

      def fire_on_entity(entity, action)
        true
      end

      def fire_on_entities(entities, action)
        entities.each do |entity|
          fire_on_entity(entity, action)
        end
      end

      def before_perform(entity_or_entities, action)
        true
      end

      def after_perform(entity_or_entities, action)
        true
      end

      def settings
        @easy_integration.metadata_settings || {}
      end

    end
  end
end
