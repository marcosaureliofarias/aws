module EasyCore
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    initializer 'easy_core.setup' do
      # Custom initializer
    end

  end
end
