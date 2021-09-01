require 'rys'

module Ryspec
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    initializer 'ryspec.setup' do
      # Custom initializer
    end

  end
end
