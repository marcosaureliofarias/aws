module EasyIntegrations
  module Trigger
    extend ActiveSupport::Concern

    included do

      after_create_commit :fire_easy_integrations_on_create
      after_update_commit :fire_easy_integrations_on_update
      # after_destroy_commit :fire_easy_integrations_on_destroy

    end

    protected

    def fire_easy_integrations_on_create
      EasyIntegrations::CanBeTriggeredOnEntityJob.perform_later(self, 'create')
    end

    def fire_easy_integrations_on_update
      EasyIntegrations::CanBeTriggeredOnEntityJob.perform_later(self, 'update')
    end

    # def fire_easy_integrations_on_destroy
    #   EasyIntegrations::CanBeTriggeredOnEntityJob.perform_later(self, 'destroy')
    # end

  end
end
