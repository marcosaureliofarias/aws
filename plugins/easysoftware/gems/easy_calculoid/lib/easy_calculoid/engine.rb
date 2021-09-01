require 'rys'

module EasyCalculoid
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_calculoid'

    initializer 'easy_calculoid.setup' do
      # Custom initializer
    end

  end
end
