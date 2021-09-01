module EasyIntegrations
  class CanBeTriggeredOnEntityJob < ::EasyIntegrations::BaseJob

    def perform(entity, action)
      EasyIntegration.find_for(entity, action).each do |easy_integration|
        if easy_integration.use_query?
          # evaluate
        end

        FireJob.perform_later(easy_integration, entity, action)
      end
    end

  end
end
