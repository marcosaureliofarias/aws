require 'rys'

module EasyIntegrations
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_integrations'
  
    initializer 'easy_integrations.setup' do

      EasyIntegrations::Metadata::RocketChat.register :rocket_chat

    end
  end
end
