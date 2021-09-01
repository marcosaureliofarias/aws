require 'rys'

module EasyZapier
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    initializer 'easy_zapier.setup' do
      # Custom initializer
    end

  end
end
