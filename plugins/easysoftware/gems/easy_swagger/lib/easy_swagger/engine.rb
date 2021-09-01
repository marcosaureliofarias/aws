require 'rys'

module EasySwagger
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_swagger'

    initializer 'easy_swagger.setup' do
      # Custom initializer
    end

    initializer :assets do |_app|
      config.assets.precompile << 'easy_swagger/application.css'
      config.assets.precompile << 'easy_swagger/application.js'
    end


  end
end
