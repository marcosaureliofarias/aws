require 'rys'

module EasyServiceManager
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_service_manager'

    initializer 'easy_service_manager.setup' do
      # Custom initializer
    end

  end
end
