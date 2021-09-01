module EasyIntegrations
  class FireJob < ::EasyIntegrations::BaseJob

    def perform(easy_integration, entity_or_entities, action)
      service = easy_integration.service

      return false if !service
      return false if !easy_integration.active?
      return false if entity_or_entities.is_a?(::ActiveRecord::Base) && !easy_integration.can_perform_on?(entity_or_entities, action)

      service.perform(entity_or_entities, action)

      save_log(easy_integration, entity_or_entities, action, status: service.status, return_value: service.return_value)

      true
    end

    private

    def save_log(easy_integration, entity_or_entities, action, status:, return_value:)
      Array(entity_or_entities).each do |entity|
        easy_integration.easy_integration_logs.create(
            entity: entity,
            status: status,
            action: action,
            return_value: return_value)
      end
    end

  end
end
