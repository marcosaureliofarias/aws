module EasyIntegrations
  class BaseJob < Rorys.task
    queue_as :easy_integrations

  end
end
