module EasyIntegrations
  class PeriodicalJob < ::EasyIntegrations::BaseJob

    def perform
      EasyIntegration.active.periodical.each do |easy_integration|
        finder = EntitiesFinder.new(easy_integration)
        if easy_integration.grouped_notify? && finder.entities.present?
          FireJob.perform_later(easy_integration, finder.entities, 'time')
        else
          finder.entities.each do |entity|
            FireJob.perform_later(easy_integration, entity, 'time')
          end
        end
      end
    end

  end
end
